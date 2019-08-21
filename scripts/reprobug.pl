#!/bin/perl

# Reproduce and hopefully get a test case for a bug initially hit by RQG
# Script-specific options are:
# - --output=<string> -- the pattern to search for, mandatory
# - --basedirX=<path to the basedir>, mandatory, but can be a part of RQG options
# - --cnf=<path to cnf file>, optional
# - --logdir=<path to the logdir>, optional, defaults to /dev/shm/
# - --mtr-thread=<number>, optional, defaults to 400 (note the difference from mtr-build-thread)
# - --rqg-home=<path to RQG>, optional
# - --server-log=<path to the general log> -- general log from the original failure, optional
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

use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
Getopt::Long::Configure("pass_through");

use strict;

my ($basedir, $cnf_file, $logdir, $mtr_thread, $output, $rqg_home, $server_log);
my $scriptdir = dirname(abs_path($0));

my $opt_result = GetOptions(
    'basedir|basedir1=s' => \$basedir,
    'cnf|cnf-file|cnf_file=s' => \$cnf_file,
    'mtr-thread|mtr_thread=i' => \$mtr_thread,
    'logdir|log-dir|log_dir=s' => \$logdir,
    'output=s' => \$output,
    'rqg-home|rqg_home=s' => \$rqg_home,
    'server-log|server_log=s' => \$server_log,
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

$logdir= '/dev/shm' unless defined $logdir;
$mtr_thread= 400 unless defined $mtr_thread;
$rqg_home= $ENV{RQG_HOME} unless defined $rqg_home;

my @mtr_options= (
    '--mtr-build-thread='.$mtr_thread,
    '--testcase-timeout=120',
    '--vardir='.$logdir.'/repro_vardir_'.$mtr_thread.'_mtr',
    '--mysqld=--innodb',
    '--mysqld=--default-storage-engine=InnoDB',
    '--mysqld=--partition',
    '--mysqld=--loose-innodb-stats-persistent=on',
    '--mysqld=--character-set-server=utf8',
    '--mysqld=--max-allowed-packet=128M',
    '--mysqld=--innodb-buffer-pool-size=128M',
    '--mysqld=--innodb-log-file-size=48M',
    '--mysqld=--loose-max-statement-time=10',
    '--mysqld=--innodb-lock-wait-timeout=3',
    '--mysqld=--lock-wait-timeout=5',
    '--mysqld=--log_bin_trust_function_creators=OFF',
    '--mysqld=--key_buffer_size=128M',
    '--mysqld=--performance-schema=OFF',
);

if ($basedir =~ /10\.[4-9]/) {
    push @mtr_options, '--mysqld=--use_stat_tables=PREFERABLY';
}

my @rqg_mandatory_options= ();
my @rqg_removable_options= ();
my $rqg_threads;

foreach my $o (@ARGV) {
    # We will use our own vardirs and ports
    next if ($o =~ /^(?:--vardir|--port|mtr[-_]build[-_]thread)/);
    
    if ($o =~ /^(?:--mysqld1?|--ps-protocol)/) {
        $o =~ s/--mysqld1/--mysqld/;
        push @mtr_options, $o;
        push @rqg_removable_options, $o;
    }
    elsif ($o =~ /^(?:--grammar|--gendata=|--duration|--skip-gendata)/) {
        push @rqg_mandatory_options, $o;
    }
    elsif ($o =~ /^--threads=(\d+)/) {
        $rqg_threads= $1;
    }
    elsif ($o =~ /^(\S+)\/runall/) {
        $rqg_home= $1 unless defined $rqg_home;
    }
    elsif ($o =~ /^--/) {
        push @rqg_removable_options, $o;
    }
}

$rqg_threads= 10 unless defined $rqg_threads;

push @rqg_mandatory_options, '--basedir='.$basedir;
push @rqg_mandatory_options, '--mtr-build-thread='.$mtr_thread;
push @rqg_mandatory_options, '--vardir='.$logdir.'/repro_vardir_'.$mtr_thread.'_rqg';
push @rqg_mandatory_options, '--trials=10';
push @rqg_mandatory_options, '--output="'.$output.'"';

my $result= 1;

if (defined $server_log and -e $server_log) {
    $result= mtr_simplification($server_log);
} else {
    print "General log not provided, running RQG first\n";
    my $res= rqg_trials();
    if ($res != 0) {
        print "RQG trials failed to reproduce, giving up\n";
        exit 1;
    }
    $result= mtr_simplification($logdir.'/repro_vardir_'.$mtr_thread.'_rqg/mysql.log');
}

while ($result != 0)
{
    if (scalar @rqg_removable_options) {
        my $opt= shift @rqg_removable_options;
        print "Trying to remove option $opt from the command line\n";
        my $res= rqg_trials();
        if ($res != 0) {
            print "RQG trials failed to reproduce, keeping the options\n";
            push @rqg_mandatory_options, $opt;
        }
    } elsif ($rqg_threads > 1) {
        $rqg_threads--;
        print "Trying to reduce the number of threads to $rqg_threads\n";
        my $res= rqg_trials();
        if ($res != 0) {
            print "RQG trials failed to reproduce, giving up\n";
            exit 1;
        }
    } else {
        print "Ran out of options to try, giving up\n";
        exit 1;
    }
    if (-e $logdir.'/repro_vardir_'.$mtr_thread.'_rqg/my.cnf') {
        $cnf_file= $logdir.'/repro_vardir_'.$mtr_thread.'_rqg/my.cnf';
    }
    $result= mtr_simplification($logdir.'/repro_vardir_'.$mtr_thread.'_rqg/mysql.log');

}

sub rqg_trials {
    unless (defined $rqg_home) {
        print "ERROR: RQG home is not defined, cannot run the test\n";
        exit 1;
    }
    system("perl $rqg_home/runall-trials.pl @rqg_mandatory_options @rqg_removable_options --threads=$rqg_threads > $logdir/repro_trials_$mtr_thread.log 2>&1");
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
    }
    system("rm -rf $suitedir; mkdir $suitedir; perl $scriptdir/mysql_log_to_mysqltest.pl $log > $suitedir/${testname}.test");
    print "Log file size: ".(-s $log).", test file size: ".(-s "$suitedir/${testname}.test")."\n\n";
    print "Running simplification\n";
    system("cd $basedir/mysql-test; perl $scriptdir/simplify-mtr-test.pl --initial-trials=10 --suitedir=$suitedir --testcase=$testname --options=\"$cnf_options @mtr_options\" --output=\"$output\"");
    my $res= $?>>8;
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
    }
    else {
        print "MTR simplification failed\n";
    }
    system("rm -rf $suitedir");
    return $res;
}
