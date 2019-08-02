#!/usr/bin/perl

use POSIX ":sys_wait_h";
use Getopt::Long;
use strict;

my ($queue_file, $lastline_file, $sleep, $max_workers, $logdir, $base_mtr_build_thread, $test_timeout);

GetOptions (
  "queue=s" => \$queue_file,
  "lastline=s" => \$lastline_file,
  "sleep=i" => \$sleep,
  "workers=i" => \$max_workers,
  "logdir=s" => \$logdir,
  "mtr-build-thread=i" => \$base_mtr_build_thread,
  "test-timeout=i" => \$test_timeout,
);

$|=1;

$sleep ||= 30;
$max_workers ||= 10;
$logdir ||= '$ENV{HOME}/logs';
$base_mtr_build_thread ||= 200;
$test_timeout ||= 7200;

my $lastline=`cat $lastline_file` || 0;
my %worker_build_threads= ();
my %worker_queue_lines= ();
my %worker_full_ids= ();
my %worker_start_times= ();
chomp $lastline;
say("Last executed line: $lastline");

# These values might be written to the schedule as
### TEST_ALIAS=<test nickname>
### SERVER_BRANCH=<branch under test>
# If set, they'll be used for writing to the database

my ($test_alias, $server_branch);

my $separator= '======================================================';

while (1) {

    unless (-e $queue_file) {
        say("The queue file $queue_file doesn't exist, waiting...");
        sleep $sleep;
        next;
    }

    my $queue_length=`wc -l $queue_file` || 0;
    chomp $queue_length;

    if ($queue_length == 0) {
        say("The queue is empty, waiting for updates...");
        sleep $sleep;
        next;
    }

    if ($lastline == $queue_length) {
        say("All $lastline line(s) in the queue file have been executed, waiting for updates...");
        sleep $sleep;
        next;
    }

    if ($lastline > $queue_length) {
        say("Last executed line is $lastline, queue length $queue_length is less than that, assuming that queue was overridden and starting from the beginning");
        $lastline= 0;
    }

    open(QUEUE, $queue_file) || die "FATAL ERROR: Couldn't open queue $queue_file for reading: $!\n";
    say("Skipping $lastline line(s) in the schedule\n");
    foreach (1..$lastline) {
        my $l=<QUEUE>;
        if ($l =~ /^\#\#\#\s*TEST_ALIAS=(.*)/i) {
            $test_alias= $1;
            chomp $test_alias;
        } elsif ($l =~ /^\#\#\#\s*SERVER_BRANCH=(.*)/i) {
            $server_branch= $1;
            chomp $server_branch;
        }
    }
    while (my $l=<QUEUE>) {
        $lastline++;
        # Skip comments and empty lines, but pay attention
        # to "special" comments
        if ($l =~ /^\s*\#/ || $l =~ /^\s*$/) {
            if ($l =~ /^\#\#\#\s*TEST_ALIAS=(.*)/i) {
                $test_alias= $1;
                chomp $test_alias;
            } elsif ($l =~ /^\#\#\#\s*SERVER_BRANCH=(.*)/i) {
                $server_branch= $1;
                chomp $server_branch;
            }
            write_lastline($lastline);
            next;
        }
        chomp $l;
        say("New test set: TEST_ALIAS=$test_alias, SERVER_BRANCH=$server_branch");
        my $res= run_test($l);
        write_lastline($lastline) if $res == 0;
    }
    close(QUEUE);
}

sub collect_finished_workers {
    my $status="Worker status <[pid mtr_build_thread status]>:";
    foreach my $p (keys %worker_build_threads) {
        waitpid($p, WNOHANG);
        my $res= $?;
        $status .= " [$p $worker_build_threads{$p} $res]";
        if ($res > -1) { # process exited
            say("Worker with pid $p (mtr_build_thread $worker_build_threads{$p}) has finished execution of queue line $worker_queue_lines{$p}");
            delete $worker_build_threads{$p};
            delete $worker_queue_lines{$p};
        } elsif ($worker_start_times{$p} + $test_timeout < time()) {
            my $id= $worker_full_ids{$p};
            say("Worker with pid $p ($id) has been running too long, trying to terminate");
            system("kill `ps -ef | grep $id | awk '{print \$2}' | xargs`");
        }
    }
    say($status);
}

sub run_test {
    my $cmd= shift;

    while (scalar(keys %worker_build_threads)) {
        collect_finished_workers();
        my @ids= keys %worker_build_threads;
        if (scalar(@ids) < $max_workers) {
            # We have a free worker, won't wait anymore
            last;
        } else {
            say("All $max_workers workers are busy: [ @ids ]. Waiting...");
            sleep $sleep;
        }
    }
    my $prefix= sprintf("%02d%02d.%02d%02d%02d.%07d",(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0],$lastline);
    # Process the command line a little: remove redirection,
    # replace it with our own,
    # replace vardir values with our own,
    # resolve symlinks,
    # use unique mtr-build-thread

    $cmd =~ s/2>&1.*//;
    $cmd =~ s/--vardir(.*)=[\/\S]+/--vardir${1}=$logdir\/${prefix}_vardir${1}/g;
    $cmd =~ s/--mtr-build-thread=\S+//g;
    $cmd =~ s/(--basedir\d*)=([\/\S]+)/$1=`realpath $2`/g;

    my %used_mtr_build_threads= reverse %worker_build_threads;
    my $mtr_build_thread= $base_mtr_build_thread;
    while (exists $used_mtr_build_threads{$mtr_build_thread}) {
        $mtr_build_thread++;
    };

    $cmd .= " --mtr-build-thread=$mtr_build_thread";
    $cmd .= " > $logdir/${prefix}_trial.log 2>&1";
    
    my $worker_pid= fork();
    if ($worker_pid) {
        $worker_build_threads{$worker_pid}= $mtr_build_thread;
        $worker_queue_lines{$worker_pid}= $lastline;
        $worker_full_ids{$worker_pid}= $prefix;
        $worker_start_times{$worker_pid}= time();
        say("Worker for line $lastline has been started with pid $worker_pid to execute the command:", "\t$cmd");
        return 0;
    } elsif (defined $worker_pid) {
        system("cd $ENV{RQG_HOME}; $cmd");

        my $resline=
           `grep 'runall.* will exit with exit status' $logdir/${prefix}_trial.log`
        || `grep 'GenTest exited with exit status' $logdir/${prefix}_trial.log`
        || `grep 'GenTest will exit with exit status' $logdir/${prefix}_trial.log`;

        my $res='N/A';
        if ($resline =~ /exit status STATUS_([A-Z_]+)/s) {
            $res= $1;
        }

        git_pull($ENV{RQG_HOME});
        $cmd= "SERVER_BRANCH=$server_branch TEST_ALIAS=$test_alias TEST_RESULT=$res TEST_ID=$prefix LOCAL_CI=`hostname` perl $ENV{RQG_HOME}/util/check_for_known_bugs.pl --signatures=$ENV{RQG_HOME}/data/bug_signatures --signatures=$ENV{RQG_HOME}/data/bug_signatures.es " . '`find ' . "$logdir/${prefix}" . '_vardir* -name mysql*.err*` `find ' . "$logdir/${prefix}" . '_vardir* -name mbackup*.log` --last=' . "$logdir/${prefix}_trial.log";
        system("echo Test result: $res > $logdir/${prefix}_postmortem; echo $cmd >> $logdir/${prefix}_postmortem; $cmd >> $logdir/${prefix}_postmortem 2>&1");
        if ($res eq 'OK') {
            system("rm -rf $logdir/${prefix}_vardir*");
        } else {
            system("cd $logdir; tar zcf archive/${prefix}_vardir.tar.gz ${prefix}_vardir*; rm -rf ${prefix}_vardir*");
        }
        system("mv $logdir/${prefix}_* $logdir/archive/");
        exit $?>>8;
    } else {
        say("ERROR: Could not fork for the test job!");
        return 1;
    }
}

sub write_lastline {
    my $lineno= shift;
    if (open(LASTLINE, ">$lastline_file")) {
        print LASTLINE $lineno;
        close(LASTLINE);
    } else {
        say("ERROR: Couldn't open $lastline_file for writing: $!");
    }
}

sub say {
    my $ts= sprintf("%04d-%02d-%02d %02d:%02d:%02d",(localtime())[5]+1900,(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0]);
    my @lines= ();
    map { push @lines, split /\n/, $_ } @_;
    foreach my $l (@lines) {
        print $ts, ' ', $l, "\n";
    }
}

sub git_pull {
    system("cd $_[0] && git pull");
}
