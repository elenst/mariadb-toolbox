#!/bin/perl

# Reproduce and hopefully get a test case for a bug initially hit by RQG
# Script-specific options are:
# - --output=<string> -- the pattern to search for, mandatory
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
Getopt::Long::Configure("pass_through");

use strict;

my ($basedir, $cnf_file, $logdir, $mtr_thread, $output, $rqg_home, $server_log, $test_id);
my $scriptdir = dirname(abs_path($0));
my $host=`hostname`;
my $id= time();
chomp $host;

my $opt_result = GetOptions(
    'basedir|basedir1=s' => \$basedir,
    'cnf|cnf-file|cnf_file=s' => \$cnf_file,
    'mtr-thread|mtr_thread=i' => \$mtr_thread,
    'logdir|log-dir|log_dir=s' => \$logdir,
    'output=s' => \$output,
    'rqg-home|rqg_home=s' => \$rqg_home,
    'server-log|server_log=s' => \$server_log,
    'test-id|test_id|testid=s' => \$test_id,
);

if (not defined $basedir) {
    print "ERROR: basedir is not defined\n";
    exit 1;
} elsif (not -d "$basedir") {
    print "ERROR: basedir ($basedir) does not exist, is not readable, or is not a directory\n";
    exit 1;
}

if (defined $rqg_home and not -d "$rqg_home") {
    print "ERROR: rqg_home ($rqg_home) does not exist, is not readable, or is not a directory\n";
    exit 1;
}

unless (defined $output) {
    print "ERROR: search pattern (--output) is not defined\n";
    exit 1;
}

$mtr_thread= 400 unless defined $mtr_thread;
$rqg_home= $ENV{RQG_HOME} unless defined $rqg_home;
$logdir= '/dev/shm' unless defined $logdir;
my $workdir= $logdir.'/repro_'.$mtr_thread;

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
    '--testcase-timeout=120',
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
push @rqg_options, '--trials=5';

my $result= 1;

if (defined $server_log and -e $server_log) {
    register_repro_stage('MTR: original log');
    $result= mtr_simplification($server_log);
} else {
    print "General log not provided, running RQG trials first\n";
    register_repro_stage('RQG: trials');
    my $res= rqg_trials($workdir.'/rqg_trials');
    if ($res != 0) {
        print "RQG trials failed to reproduce, giving up\n";
        register_repro_stage("FAILED (RQG trials)");
        exit 1;
    }
    register_repro_stage('MTR: from RQG log');
    $result= mtr_simplification($workdir.'/rqg_trials/mysql.log');
    if ($result == 0) {
        register_repro_stage("SUCCEEDED (on MTR)");
        exit 0;
    }
}

print "MTR simplification of the original log failed, trying RQG simplification\n";
register_repro_stage("RQG: simplification");
my $rqg_result= rqg_simplification($workdir.'/rqg_simplification');
if ($rqg_result != 0) {
    print "RQG simplification failed, giving up\n";
    register_repro_stage("FAILED (RQG simplification)");
    exit 1;
}

register_repro_stage('MTR: from simplified RQG');
$result= mtr_simplification($workdir.'/rqg_simplification/vardir/mysql.log');
if ($result == 0) {
    register_repro_stage("SUCCEEDED (on MTR)");
} else {
    print "MTR simplifcication failed, staying with simplified RQG grammar\n";
    register_repro_stage("SUCCEEDED (on RQG)");
}
exit 0;

sub rqg_trials {
    my $vardir= shift;
    unless (defined $rqg_home) {
        print "ERROR: RQG home is not defined, cannot run the test\n";
        register_repro_stage("Failed: RQG_HOME not defined");
        exit 1;
    }
    print "Running RQG test: perl $rqg_home/runall-trials.pl --mtr-build-thread=$mtr_thread @rqg_options --threads=$rqg_threads > $workdir/rqg_trials.out\n";
    system("cd $rqg_home; perl $rqg_home/runall-trials.pl --vardir=$vardir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_trials.out 2>&1");
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
    print "Running RQG simplification: perl $rqg_home/util/simplify-rqg-test.pl --mtr-thread=$mtr_thread --workdir=$wdir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_simplification.out\n";
    system("cd $rqg_home; perl $rqg_home/util/simplify-rqg-test.pl --workdir=$wdir --output=\"$output\" @rqg_options --threads=$rqg_threads > $workdir/rqg_simplification.out 2>&1");
    return $?>>8;
}

sub mtr_simplification {
    my $log= shift;
    print "\nCreating an MTR test from $log\n";
    my $suitedir= "$basedir/mysql-test/suite/repro_$mtr_thread";
    my $testname= "repro${mtr_thread}";
    my $cnf_options="";
    if (defined $cnf_file and -e $cnf_file) {
        $cnf_options=`perl $scriptdir/cnf_to_command_line.pl $cnf_file`;
        chomp $cnf_options;
        $cnf_options =~ s/--mysqld=--loose-(innodb[-_]page[-_]size|checksum[-_]algorithm|undo[-_]tablespaces|log[-_]group[-_]home[-_]dir|data[-_]home[-_]dir|data[-_]file[-_]path)/--mysqld=--$1/g;
    }
    system("rm -rf $suitedir; mkdir $suitedir; perl $scriptdir/mysql_log_to_mysqltest.pl $log > $suitedir/${testname}.test");
    print "Log file size: ".(-s $log)." ($log)\n";
    print "Test file size: ".(-s "$suitedir/${testname}.test")." ($suitedir/${testname}.test)\n\n";
    print "Running simplification\n";
    my $cmd1= "cd $basedir/mysql-test; perl $scriptdir/simplify-mtr-test.pl --initial-trials=10 --suitedir=$suitedir --testcase=$testname --options=\"$cnf_options @mtr_options @mtr_timeouts\" --output=\"$output\"";
    my $cmd2= "cd $basedir/mysql-test; perl $scriptdir/simplify-mtr-test.pl --initial-trials=3 --suitedir=$suitedir --testcase=$testname --options=\"$cnf_options @mtr_options\" --output=\"$output\"";
    print "First attempt with low timeouts, if it doesn't work, try without them\n\n";

    my $res;
    foreach my $cmd ($cmd1, $cmd2) {
        print "Command line\n$cmd1\n\n";
        system($cmd);
        $res= $?>>8;
        if ($res == 0) {
            my $cnt= 0;
            while (-e "$logdir/$testname.test.$cnt") {
                $cnt++;
            }
            system("echo \"# Search pattern: $output\" > $logdir/$testname.test.$cnt");
            system("echo \"# Basedir: $basedir\" >> $logdir/$testname.test.$cnt");
            system("echo \"# MTR options: @mtr_options\" >> $logdir/$testname.test.$cnt");
            system("echo \"\" >> $logdir/$testname.test.$cnt");
            system("cat $suitedir/new_test.test >> $logdir/$testname.test.$cnt");
            print "MTR simplification succeeded, resulting MTR test is $logdir/$testname.test.$cnt\n";
            system("rm -rf $suitedir");
            last;
        }
        else {
            print "MTR simplification failed\n";
        }
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
