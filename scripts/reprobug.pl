#!/bin/perl

# Reproduce and hopefully get a test case for a bug initially hit by RQG
# Script-specific options are:
# - --output=<string> -- the pattern to search for, mandatory
# - --preserve-query=<string> -- the pattern to preserve
# - --cnf=<path to cnf file>, optional
# - --logdir=<path to the logdir>, optional, defaults to /dev/shm/
# - --mtr-thread=<number>, optional, defaults to 400 (note the difference from mtr-build-thread)
# - --rqg-home=<path to RQG>, optional
# - --server-log=<path to the general log> -- general log from the original failure, optional
# - --test-id=<test ID> -- optional, for registration purposes only
# - --basedirX=<path to the basedir>, mandatory, but can be a part of RQG options
# Other options are assumed to be the original RQG line.
# Out of them, --mysqld=--<..> options are passed over to MTR when MTR test is tried,
# and all of them are initially passed over to RQG for RQG reproducing if needed.

# The algorithm is:
# 1) If server-log is defined, first try to convert it into MTR test case
#   and do testcase simplification.
# 2) If it succeeds, stop at it.
# 3) If (1) fails or gets skipped, run RQG trials
# 4) If (3) fails, stop and admit defeat
# 5) If (3) succeeds to reproduce, pick up the general log and try MTR simplification [again]
# 6) If (5) succeeds, stop at it.
# 7) If (5) fails, try to simplify RQG command line and go back to (3)

use DBI;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use POSIX ":sys_wait_h";
Getopt::Long::Configure("pass_through");

use strict;

my ($basedir, $cnf_file, $logdir, $mtr_thread, $mtr_timeout, $mtr_trials, $output, $preserve_query, $rqg_home, $rqg_trials, $server_log, $test_id);
my $scriptdir = dirname(abs_path($0));
my $host=`hostname`;
my $id= time();
my $skip_mtr= 0;
my $skip_rqg= 0;
chomp $host;

# Some defaults
$mtr_thread= 400;
$mtr_trials= 3;
$rqg_trials= 5;
$mtr_timeout= 120;
$logdir= '/dev/shm';
$rqg_home= $ENV{RQG_HOME};

my $opt_result = GetOptions(
    'basedir|basedir1=s' => \$basedir,
    'cnf|cnf-file|cnf_file=s' => \$cnf_file,
    'mtr-thread|mtr_thread=i' => \$mtr_thread,
    'mtr-timeout|mtr_timeout=i' => \$mtr_timeout,
    'mtr-trials|mtr_trials=i' => \$mtr_trials,
    'logdir|log-dir|log_dir=s' => \$logdir,
    'output=s' => \$output,
    'preserve-query|preserve_query=s' => \$preserve_query,
    'rqg-home|rqg_home=s' => \$rqg_home,
    'rqg-trials|rqg_trials=i' => \$rqg_trials,
    'server-log|server_log=s' => \$server_log,
    'skip-mtr|skip_mtr' => \$skip_mtr,
    'skip-rqg|skip_rqg' => \$skip_rqg,
    'test-id|test_id|testid=s' => \$test_id,
);

if (not defined $basedir) {
    print "ERROR: basedir is not defined\n";
    exit 1;
} elsif (not -d "$basedir") {
    print "ERROR: basedir ($basedir) does not exist, is not readable, or is not a directory\n";
    exit 1;
}

unless (-d "$rqg_home") {
    print "ERROR: rqg_home ($rqg_home) does not exist, is not readable, or is not a directory\n";
    exit 1;
}

unless (defined $output) {
    print "ERROR: search pattern (--output) is not defined\n";
    exit 1;
}

my $workdir= $logdir.'/repro_'.$mtr_thread;
system("rm -rf $workdir; mkdir -p $workdir");
if ($? != 0) {
    print "ERROR: could not create workdir $workdir\n";
    exit 1;
}

$SIG{INT}  = sub { register_repro_stage('aborted'); exit(1) };
$SIG{TERM} = sub { register_repro_stage('aborted'); exit(1) };
$SIG{ABRT} = sub { register_repro_stage('aborted'); exit(1) };
$SIG{SEGV} = sub { register_repro_stage('crashed'); exit(1) };
$SIG{KILL} = sub { register_repro_stage('aborted'); exit(1) };

print "Initial options:\n";
print "    Search pattern: $output\n";
print "    Basedir: $basedir\n";
print "    Config file: $cnf_file\n";
print "    Workdir: $workdir\n";
print "    RQG home: $rqg_home\n";
print "    Server log: $server_log\n";
print "    Test ID: $test_id\n\n";

my @mtr_options= (
    '--testcase-timeout='.$mtr_timeout,
    '--vardir='.$workdir.'/mtr',
    '--mysqld=--innodb',
    '--mysqld=--default-storage-engine=InnoDB',
    '--mysqld=--partition',
    '--mysqld=--loose-innodb-stats-persistent=on',
    '--mysqld=--character-set-server=utf8',
    '--mysqld=--max-allowed-packet=128M',
    '--mysqld=--innodb-buffer-pool-size=128M',
    '--mysqld=--innodb-log-file-size=48M',
    '--mysqld=--log_bin_trust_function_creators=OFF',
    '--mysqld=--key_buffer_size=128M',
    '--mysqld=--performance-schema=OFF',
);

my @mtr_timeouts= (
    '--mysqld=--loose-max-statement-time=10',
    '--mysqld=--innodb-lock-wait-timeout=3',
    '--mysqld=--lock-wait-timeout=5',
);

if ($basedir =~ /10\.[4-9]/) {
    push @mtr_options, '--mysqld=--use_stat_tables=PREFERABLY';
}

my @rqg_options= ();
my $rqg_threads;

foreach my $o (@ARGV) {
    # We will use our own vardirs and ports
    next if ($o =~ /^(?:--vardir|--port|--mtr[-_]build[-_]thread)/);
    
    if ($o =~ /^--mysqld1?=--server[-_]id=\d+/) {
        # MTR doesn't like custom server IDs, only keep it for RQG
        push @rqg_options, $o;
    }
    elsif ($o =~ /^(?:--mysqld1?|--ps-protocol)/) {
        $o =~ s/--mysqld1/--mysqld/;
        push @mtr_options, $o;
        push @rqg_options, $o;
    }
    elsif ($o =~ /^--threads=(\d+)/) {
        $rqg_threads= $1;
    }
    elsif ($o =~ /^(\S+)\/runall/) {
        $rqg_home= $1 unless defined $rqg_home;
    }
    elsif ($o =~ /^--/) {
        push @rqg_options, $o;
    }
}

$rqg_threads= 10 unless defined $rqg_threads;

push @rqg_options, '--basedir='.$basedir;
push @rqg_options, '--trials='.$rqg_trials;

my $result= 1;

if (not $skip_mtr and not (defined $server_log and -e $server_log))
{
    print "General log for MTR simplification not provided, running RQG trials first\n";
    register_repro_stage('RQG: trials');
    $result= rqg_trials($workdir.'/rqg_trials');
    if ($result != 0) {
        print "RQG trials failed to reproduce, giving up\n";
        register_repro_stage("FAILED (RQG trials)");
        exit $result;
    } elsif (-e "$workdir/rqg_trials/mysql.log") {
        $server_log= "$workdir/rqg_trials/mysql.log";
    } else {
        print "RQG trials did not produce any log, nothing to use for MTR\n";
        $skip_mtr= 1;
    }
}

if ($skip_mtr) {
    print "MTR simplification is skipped by configuration or previous checks\n";
} else {
    $result= mtr_simplification($server_log, 'initial');
    if ($result == 0) {
        register_repro_stage("SUCCEEDED (on MTR)");
        exit $result;
    } else {
        register_repro_stage("FAILED (on MTR)");
    }
}

if ($skip_rqg) {
    print "RQG simplification is skipped by configuration\n";
    exit $result;
} else {
    print "MTR simplification of the original log failed or was skipped, trying RQG simplification\n";
    $result= rqg_simplification($workdir.'/rqg_simplification');
    if ($result != 0) {
        print "RQG simplification failed, giving up\n";
        register_repro_stage("FAILED (RQG simplification)");
        exit $result;
    }
}

if ($skip_mtr) {
    print "MTR simplification is skipped by configuration or previous checks\n";
} elsif (-e "$workdir/rqg_simplification/vardir/mysql.log") {
    $result= mtr_simplification($workdir.'/rqg_simplification/vardir/mysql.log', 'from simplified RQG');
    if ($result == 0) {
        register_repro_stage("SUCCEEDED (on MTR)");
        exit $result;
    } else {
        print "MTR simplifcication failed, staying with simplified RQG grammar\n";
    }
} else {
    print "RQG simplification did not produce any log, nothing to use for MTR\n";
}

register_repro_stage("SUCCEEDED (on RQG)");
exit $result;


########################################################################

sub rqg_trials {
    my $vardir= shift;
    unless (defined $rqg_home) {
        print "ERROR: RQG home is not defined, cannot run the test\n";
        register_repro_stage("Failed: RQG_HOME not defined");
        exit 1;
    }
    print "\nRunning RQG test: perl $rqg_home/runall-trials.pl --mtr-build-thread=$mtr_thread --vardir=$vardir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_trials.out\n";
    system("cd $rqg_home; perl $rqg_home/runall-trials.pl --mtr-build-thread=$mtr_thread --vardir=$vardir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_trials.out 2>&1");
    my $res= $?>>8;
    system("grep -E 'will exit with exit status|exited with exit status' $workdir/rqg_trials.out");
    return $res;
}

sub rqg_simplification {
    my $wdir= shift;
    unless (defined $rqg_home) {
        print "ERROR: RQG home is not defined, cannot run the simplification\n";
        register_repro_stage("Failed: RQG_HOME not defined");
        exit 1;
    }
    my $pid= fork();

    if ($pid) {
        print "\nRunning RQG simplification: perl $rqg_home/util/simplify-rqg-test.pl --mtr-thread=$mtr_thread --workdir=$wdir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_simplification.out\n";
        my $stage= 'RQG simplification';
        register_repro_stage($stage);
        my $prev_stage= $stage;
        do {
            sleep 60;
            my $last_success=`grep SUCCESS $workdir/rqg_simplification.out | tail -n 1`;
            if ($last_success =~ /\/(\d+)\.yy\s+\#/) {
                $stage= "RQG grammar success: $1";
            } elsif ($last_success =~ /with cmd (\d+)/) {
                $stage= "RQG cmd success: $1";
            }
            if ($stage ne $prev_stage) {
                register_repro_stage($stage);
                $prev_stage= $stage;
            }
            waitpid($pid, WNOHANG);
        } until ($? > -1);
        return $?;
    } elsif (defined $pid) {
        system("cd $rqg_home; perl $rqg_home/util/simplify-rqg-test.pl --mtr-thread=$mtr_thread --workdir=$wdir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_simplification.out 2>&1");
        exit $?>>8;
    } else {
      print "ERROR: Could not fork for running the test\n";
      register_repro_stage("RQG aborted");
      exit 1;
    }
}

sub mtr_simplification {
    my ($log, $stage)= @_;
    print "\nCreating an MTR test from $log\n";
    my $suitedir= "$basedir/mysql-test/suite/repro_$mtr_thread";
    my $testname= "repro${mtr_thread}";
    my $cnf_options="";
    if (defined $cnf_file and -e $cnf_file) {
        $cnf_options=`perl $scriptdir/cnf_to_command_line.pl $cnf_file`;
        chomp $cnf_options;
        $cnf_options =~ s/--mysqld=--loose-(innodb[-_]page[-_]size|checksum[-_]algorithm|undo[-_]tablespaces|log[-_]group[-_]home[-_]dir|data[-_]home[-_]dir|data[-_]file[-_]path)/--mysqld=--$1/g;
    }
    system("rm -rf $suitedir; mkdir $suitedir; perl $scriptdir/mysql_log_to_mysqltest.pl --data-location=$rqg_home/data/blobs $log | sed  -e \"s/\(IMMEDIATE\|FROM\) ' \\//\1 '' \\//g\" | sed  -e \"s/\(IMMEDIATE\|FROM\) '\$/\1 ''/g\" > $suitedir/${testname}.test");
    print "Log file size: ".(-s $log)." ($log)\n";
    print "Test file size: ".(-s "$suitedir/${testname}.test")." ($suitedir/${testname}.test)\n\n";
    print "Running simplification with short timeouts\n";
    my $res= run_mtr_simplification("cd $basedir/mysql-test; perl $scriptdir/simplify-mtr-test.pl --trials=$mtr_trials --options=\"$cnf_options @mtr_options @mtr_timeouts\" --output=\"$output\" --preserve-query=\"$preserve_query\"", $suitedir, $testname, "MTR: $stage: short");
    if ($res != 0) {
        print "\nRunning simplification without short timeouts\n";
        $res= run_mtr_simplification("cd $basedir/mysql-test; perl $scriptdir/simplify-mtr-test.pl --trials=$mtr_trials --options=\"$cnf_options @mtr_options\" --output=\"$output\" --preserve-query=\"$preserve_query\"", $suitedir, $testname, "MTR: $stage: long");
    }
    return $res;
}

sub run_mtr_simplification
{
    my ($cmd, $suitedir, $testname, $stage)= @_;
    $cmd.= " --suitedir=$suitedir --testcase=$testname";

    my $pid= fork();
    if ($pid) {
        print "Command line\n$cmd\n\n";
        register_repro_stage($stage);
        my $prev_stage= $stage;
        do {
            sleep 60;
            my $last_reproducible=`ls -t $suitedir/$testname.test.reproducible.* 2>/dev/null | head -n 1`;
            chomp $last_reproducible;
            if ($last_reproducible =~ /test.reproducible.(\d+)$/) {
                $stage= "MTR reproducible: $1";
                if ($stage ne $prev_stage) {
                    register_repro_stage($stage);
                    $prev_stage= $stage;
                }
            }
            waitpid($pid, WNOHANG);
        } until ($? > -1);
    } elsif (defined $pid) {
        system($cmd);
        exit $?>>8;
    } else {
      print "ERROR: Could not fork for running the test\n";
      register_repro_stage("MTR: aborted");
      exit 1;
    }
    my $res= $?;
    if ($res == 0) {
        my $cnt= 0;
        # Find the last reproducible test case
        while (-e "$suitedir/$testname.test.reproducible.$cnt") {
            $cnt++;
        }
        my $last_test= "$suitedir/$testname.test.reproducible.".($cnt-1);
        # Find the first vacant name for storing
        $cnt= 0;
        while (-e "$logdir/$testname.test.$cnt") {
            $cnt++;
        }
        if (open(TESTCASE,">$logdir/$testname.test.$cnt"))
        {
            print TESTCASE "# Search pattern: $output\n";
            print TESTCASE "# Pattern to preserve: $preserve_query\n";
            print TESTCASE "# Basedir: $basedir\n";
            print TESTCASE '# Command line:'.$cmd."\n\n";
            close(TESTCASE);
        } else {
            print "ERROR: Could not open $logdir/$testname.test.$cnt for writing: $!\n";
        }
        system("cat $last_test >> $logdir/$testname.test.$cnt");
        print "MTR simplification succeeded, resulting MTR test is $logdir/$testname.test.$cnt\n";
        system("rm -rf $suitedir");
    }
    else {
        print "MTR simplification failed\n";
    }
    return $res;
}

sub register_repro_stage {
    my $status= shift;
    if (defined $ENV{DB_USER}) {
        my $dbh= DBI->connect("dbi:mysql:host=$ENV{DB_HOST}:port=$ENV{DB_PORT}",$ENV{DB_USER}, $ENV{DBP}, { RaiseError => 1 } );
        if ($dbh) {
            $dbh->do("REPLACE INTO regression.repro_status (id, host, test_id, screen, mtr_thread, search_pattern, status) VALUES ($id,\'$host\',\'$test_id\',\'$ENV{STY}\',\'$mtr_thread\', \'$output\', \'$status\')");
        } else {
            print "ERROR: Couldn't connect to the database to register the result\n";
        }
    }
}
