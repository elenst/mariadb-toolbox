#!/usr/bin/perl

use POSIX ":sys_wait_h";
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;

use strict;

my ($queue_file, $lastline_file, $sleep, $max_workers, $logdir, $base_mtr_build_thread, $test_timeout, $backlog_file);

my $path = dirname(abs_path($0));

GetOptions (
  "queue=s" => \$queue_file,
  "backlog=s" => \$backlog_file,
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

my ($test_alias, $server_branch, $server_revno);
my ($backlog_test_alias, $backlog_server_branch);

my $backlog_test_count= 0;

sub open_backlog {
    if ($backlog_file) {
        unless (open(BACKLOG, "$backlog_file")) {
            sayError("Could not open backlog $backlog_file for reading: $!");
            $backlog_file= undef;
        }
    }
}

open_backlog();

my $separator= '======================================================';

while (1) {

    unless (-e $queue_file) {
        if ($backlog_file) {
            say("The queue file $queue_file doesn't exist, using backlog...");
            run_backlog_test();
        } else {
            say("The queue file $queue_file doesn't exist and backlog not defined, waiting...");
            sleep $sleep;
        }
        next;
    }

    my $queue_length=`wc -l $queue_file` || 0;
    chomp $queue_length;

    if ($queue_length == 0) {
        if ($backlog_file) {
            say("The queue is empty, using backlog...");
            run_backlog_test();
        } else {
            say("The queue is empty and backlog not defined, waiting for updates...");
            sleep $sleep;
        }
        next;
    }

    if ($lastline == $queue_length) {
        if ($backlog_file) {
            say("All $lastline line(s) in the queue file have been executed, using backlog...");
            run_backlog_test();
        } else {
            say("All $lastline line(s) in the queue file have been executed and backlog not defined, waiting for updates...");
            sleep $sleep;
        }
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
        process_queue_line(\$l, \$test_alias, \$server_branch);
    }
    while (my $l=<QUEUE>) {
        $lastline++;
        # Skip comments and empty lines, but pay attention
        # to "special" comments
        process_queue_line(\$l, \$test_alias, \$server_branch);
        if ($l) {
            say("New test set: TEST_ALIAS=$test_alias, SERVER_BRANCH=$server_branch");
            my $res= run_test($l, $test_alias, $server_branch, $lastline);
            write_lastline($lastline) if $res == 0;
        }
    }
    close(QUEUE);
}

sub run_backlog_test {
    my $reopened= 0;
    my $bl;
    do {
        $bl=<BACKLOG>;
        if (not defined $bl and not $reopened) {
            close(BACKLOG);
            open_backlog();
            $reopened= 1;
            $bl=<BACKLOG>;
        } elsif (not defined $bl) {
            say("Couldn't find any usable lines in backlog, discarding it from now on");
            close(BACKLOG);
            sleep $sleep;
            return;
        }
        process_queue_line(\$bl, \$backlog_test_alias, \$backlog_server_branch);
    } until (defined $bl);
    $backlog_test_count++;
    run_test($bl, $backlog_test_alias, $backlog_server_branch, $backlog_test_count);
}

# Conditionally modifies test_alias, server_branch and line.
# line stays defined if it's a test line, and goes undef otherwise
sub process_queue_line {
    my ($l_ref, $alias_ref, $branch_ref) = @_;
    if ($$l_ref =~ /^\s*\#/ || $$l_ref =~ /^\s*$/) {
        if ($$l_ref =~ /^\#\#\#\s*TEST_ALIAS=(.*)/i) {
            $$alias_ref= $1;
            chomp $$alias_ref;
        } elsif ($$l_ref =~ /^\#\#\#\s*SERVER_BRANCH=(.*)/i) {
            $$branch_ref= $1;
            chomp $$branch_ref;
        }
        $$l_ref= undef;
    } else {
        chomp $$l_ref;
    }
}

sub collect_finished_workers {
    my $status="Worker status <[pid mtr_build_thread status]>:";
    foreach my $p (keys %worker_build_threads) {
        waitpid($p, WNOHANG);
        my $res= $?;
        $status .= " [$p $worker_build_threads{$p} $res]";
        my $id= $worker_full_ids{$p};
        if ($res > -1) { # process exited
            say("Worker with pid $p (mtr_build_thread $worker_build_threads{$p}) has finished execution of queue line $worker_queue_lines{$p}");
            delete $worker_build_threads{$p};
            delete $worker_queue_lines{$p};
            say("Killing everything related to the finished test $id");
            system("kill -9 `ps -ef | grep $id | awk '{print \$2}' | xargs`");
        } elsif ($worker_start_times{$p} + $test_timeout < time()) {
            say("Worker with pid $p ($id) has been running too long, it will be terminated");
            system("kill -9 `ps -ef | grep $id | awk '{print \$2}' | xargs`");
        }
    }
    say($status);
}

sub run_test {
    my ($cmd, $test_alias, $server_branch, $counter)= @_;

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
    my $prefix= sprintf("%02d%02d.%02d%02d%02d.%07d",(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0],$counter);
    # Process the command line a little: remove redirection,
    # replace it with our own,
    # replace vardir values with our own,
    # resolve symlinks,
    # use unique mtr-build-thread

    $cmd =~ s/2>&1.*//;
    $cmd =~ s/--vardir([\S]*)=[\S]+/--vardir${1}=$logdir\/${prefix}_vardir${1}/g;
    $cmd =~ s/--mtr-build-thread=\S+//g;
    $cmd =~ s/(--basedir\d*)=([\/\S]+)/$1=`realpath $2`/g;
    if (`realpath $2` =~ /-([0-9a-f]{8})/) {
        $server_revno= $1;
    } else {
        $server_revno= 'N/A';
    }

    my %used_mtr_build_threads= reverse %worker_build_threads;
    my $mtr_build_thread= $base_mtr_build_thread;
    while (exists $used_mtr_build_threads{$mtr_build_thread}) {
        $mtr_build_thread++;
    };

    $cmd .= " --mtr-build-thread=$mtr_build_thread";
    # If wsrep is enabled (or assumed), use a unique port in wsrep_node_address
    if ($cmd =~ /wsrep[-_]cluster[-_]address/) {
        $cmd .= ' --mysqld=--wsrep-node-address=127.0.0.1:'.(4567+$mtr_build_thread);
    }
    $cmd .= " > $logdir/${prefix}_trial.log 2>&1";

    my $worker_pid= fork();
    if ($worker_pid) {
        $worker_build_threads{$worker_pid}= $mtr_build_thread;
        $worker_queue_lines{$worker_pid}= $counter;
        $worker_full_ids{$worker_pid}= $prefix;
        $worker_start_times{$worker_pid}= time();
        say("Worker for line $counter has been started with pid $worker_pid to execute the command:", "\t$cmd");
        return 0;
    } elsif (defined $worker_pid) {
        system("cd $ENV{RQG_HOME}; $cmd");
        my $exitcode= $?>>8;

        git_pull($ENV{RQG_HOME});
        system("SERVER_BRANCH=$server_branch SERVER_REVNO=$server_revno TEST_ALIAS=$test_alias TEST_ID=$prefix LOGDIR=$logdir PREFIX=$prefix $path/postmortem.sh > $logdir/${prefix}_postmortem 2>&1");
        exit $exitcode;
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
