#!/usr/bin/perl

use POSIX ":sys_wait_h";
use Getopt::Long;
use Cwd qw(abs_path realpath);
use File::Basename;

use strict;

use constant STATUS_OK => 0;

unless ($ENV{RQG_HOME}) {
  say("FATAL ERROR: RQG_HOME is not set");
  exit;
}

my $test_config;
my $logdir= "$ENV{HOME}/logs";
my $blddir= "$ENV{HOME}/bld";

GetOptions (
  "config=s" => \$test_config,
  "logdir=s" => \$logdir,
  "blddir=s" => \$blddir,
);

if (! $test_config) {
  say("FATAL ERROR: Test config is not defined");
  exit 1;
} elsif (! -e $test_config) {
  say("FATAL ERROR: Test config $test_config does not exist");
  exit 1;
} elsif (! -d $logdir) {
  say("FATAL ERROR: Log location $logdir doesn't exist or is not a directory");
  exit 1;
} elsif (! -d $blddir) {
  say("FATAL ERROR: Build location $blddir doesn't exist or is not a directory");
  exit 1;
}

my $scripts_location = dirname(abs_path($0));
my $worker= `hostname`;
chomp $worker;

# Default values, can be overridden in the test config
my $max_workers= 10;
my $base_mtr_build_thread= 200;
# That's when the test run will be forcefully killed by a watchdog
my $test_timeout= 7200;
# Minimal number of tests which should be executed before the build can be moved to 2nd tier
my $min_test_limit= 100;
# Builds older than this (in seconds) will be the 3rd tier as long as they've undergone at least min_test_limit tests
my $build_retirement_age= 1000000;

# No default value for branch/combinations --
# if none is found in config, the test will exit
my %branch_combinations= ();

# Number of tests executed for a revision
my %tests_per_build= ();
# build timestamp based on basedir modification time
my %build_time= ();
my %build_realpath= ();

# Last time the config was reloaded
# (to be compared with the config modification time)
my $config_last_load_timestamp= 0;

my %worker_build_threads= ();
my %worker_full_ids= ();
my %worker_start_times= ();

my $separator= '======================================================';
my $combinations_cmd= "perl ./combinations.pl --trials=1";

sub reload_config {
  my $config_modified= (stat("$test_config"))[9];
  if ($config_last_load_timestamp > $config_modified) {
    # Old config, already loaded
    return STATUS_OK;
  }
  $config_last_load_timestamp= time();
  open(CONFIG, "$test_config") || die "Could not open config $test_config for reading: $!\n";
  my $section_started;
  %branch_combinations= ();
  while (<CONFIG>) {
    chomp;
    s/^\s*//;
    if ($section_started) {
      next if /^\#/;
      next if /^$/;
      # Another section started
      last if /^\[\w+\]/;
      if (/^([-\w+]+)\s*=\s*(\S+)/) {
        my ($opt, $value)= ($1, $2);
        if ($opt =~ /^branch/) {
          # e.g.
          # branch = 10.3:conf/mariadb/regression/all_combinations-10.3.cc
          my ($branch, $cnf) = split /:/, $value;
          if ($branch_combinations{$branch}) {
            push @{$branch_combinations{$branch}}, $cnf;
          } else {
            $branch_combinations{$branch}= [ $cnf ];
          }
        } elsif ($opt =~ /max[-_]workers/) {
          $max_workers= $value;
        } elsif ($opt =~ /base[-_]mtr[-_]build[-_]thread/) {
          $base_mtr_build_thread= $value;
        } elsif ($opt =~ /min[-_]test[-_]limit/) {
          $min_test_limit= $value;
        } elsif ($opt =~ /build[-_]retirement[-_]age/) {
          $build_retirement_age= $value;
        }
      }
    }
    elsif (/^\s*\[$worker\]\s*$/) {
      $section_started= 1;
    }
  }
  return STATUS_OK;
}

while (1) {
  unless (reload_config() == STATUS_OK) {
    say("FATAL ERROR: Could not reload the config file");
    exit 1;
  }
  unless (scalar(keys %branch_combinations)) {
    say("FATAL ERROR: No branches are configured for the run");
    exit 1;
  }
  %build_realpath= ();
  my %branch_age= ();
  my %branch_tests= ();
  foreach my $b (keys %branch_combinations) {
    my $rpath= realpath("$blddir/$b");
    $build_realpath{$b}= $rpath;
    unless (defined $build_time{$rpath}) {
      $build_time{$rpath}= (stat("$rpath"))[9];
    }
    unless (defined $tests_per_build{$rpath}) {
      $tests_per_build{$rpath}= 0;
    }
    $branch_age{$b}= time() - $build_time{$rpath};
    $branch_tests{$b}= $tests_per_build{$rpath};
  }

  my @fresh_branches;
  my $branch_to_run;

  # Tier 1:
  # If there are builds which had less than $min_test_limit tests,
  # choose one which has the lowest number and run it
  # (additionally collect recent builds for the possible 2nd tier)
  foreach my $b (keys %branch_combinations) {
    push @fresh_branches, $b if $branch_age{$b} < $build_retirement_age;
    if ($branch_tests{$b} < $min_test_limit) {
      if (not defined $branch_to_run or $branch_tests{$b} < $branch_tests{$branch_to_run}) {
        $branch_to_run= $b;
      }
    }
  }
  # Tier 2:
  # If no such build was found, use a random build out of those which have not reached retirement age
  if (not $branch_to_run and scalar(@fresh_branches)) {
    $branch_to_run= $fresh_branches[int(rand(scalar(@fresh_branches)))];
  }
  # Tier 3:
  # If no such build was found, use a random build
  if (not $branch_to_run) {
    my @branches= keys %branch_combinations;
    $branch_to_run= $branches[int(rand(scalar(@branches)))];
  }

  unless ($branch_to_run) {
    say("FATAL ERROR: Something went wrong, we could not find a branch to run");
    exit 1;
  }

  my @combinations= @{$branch_combinations{$branch_to_run}};
  unless (scalar(@combinations)) {
    say("FATAL ERROR: Something went wrong, we could not find combinations to run");
    exit 1;
  }

  my $combinations_config= $combinations[int(rand(scalar(@combinations)))];

  run_test($combinations_config, $branch_to_run);

}

sub collect_finished_workers {
    my $status="Worker status <[pid mtr_build_thread status]>:";
    foreach my $p (keys %worker_build_threads) {
        waitpid($p, WNOHANG);
        my $res= $?;
        $status .= " [$p $worker_build_threads{$p} $res]";
        my $id= $worker_full_ids{$p};
        if ($res > -1) { # process exited
            say("Worker with pid $p (mtr_build_thread $worker_build_threads{$p}) has finished execution of $worker_full_ids{$p}");
            delete $worker_build_threads{$p};
            say("Killing everything related to the finished test $id");
            system("ps -ef | grep $id | awk '{print \$2}' | xargs kill -9");
        } elsif ($worker_start_times{$p} + $test_timeout < time()) {
            say("Worker with pid $p ($id) has been running too long, it will be terminated");
            system("ps -ef | grep $id | awk '{print \$2}' | xargs kill -9");
        }
    }
    say($status);
}

sub run_test {
  my ($config, $branch_to_run)= @_;

  my $build_to_run= $build_realpath{$branch_to_run};

  unless (-d $build_to_run) {
    say("ERROR: Something went wrong, the build directory $build_to_run does not exist");
    return 1;
  }
  my $server_revno= 'N/A';
  if ($build_to_run =~ /-([0-9a-f]{8})/) {
    $server_revno= $1;
  }

#  my $test_alias= basename("$ENV{RQG_HOME}/$config");
  my $test_alias= 'combo';

  while (scalar(keys %worker_build_threads)) {
      collect_finished_workers();
      my @ids= keys %worker_build_threads;
      if (scalar(@ids) < $max_workers) {
          # We have a free worker, won't wait anymore
          last;
      } else {
          say("All $max_workers workers are busy: [ @ids ]. Waiting...");
          sleep 30;
      }
  }

  my %used_mtr_build_threads= reverse %worker_build_threads;
  my $mtr_build_thread= $base_mtr_build_thread;
  while (exists $used_mtr_build_threads{$mtr_build_thread}) {
      $mtr_build_thread++;
  };
  # Suffix for the test run ID to make it unique in case of several workers
  # starting tests on the same second
  my $ext= $mtr_build_thread - $base_mtr_build_thread;
  
  my $test_id= sprintf("%02d%02d.%02d%02d%02d.%02d",(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0],$ext);
  my $workdir= "$logdir/$test_id";
  system("rm -rf $workdir");

  my $cmd= $combinations_cmd." --basedir=$build_to_run --config=$config --mtr-build-thread=$mtr_build_thread --workdir=$workdir > /dev/null 2>&1";

  my $worker_pid= fork();
  if ($worker_pid) {

      sub signal_handler {
          say("$$: Caught a signal $!");
      }
      $SIG{INT}  = \&signal_handler;
      $SIG{TERM} = \&signal_handler;
      $SIG{ALRM} = \&signal_handler;
      $SIG{SEGV} = \&signal_handler;
      $SIG{ABRT} = \&signal_handler;
      $SIG{USR1} = \&signal_handler;
      $SIG{USR2} = \&signal_handler;
      $SIG{CHLD} = \&signal_handler;
      $SIG{CONT} = \&signal_handler;
      $SIG{FPE} = \&signal_handler;
      $SIG{ILL} = \&signal_handler;
      $SIG{PIPE} = \&signal_handler;
      $SIG{STOP} = \&signal_handler;
      $SIG{TRAP} = \&signal_handler;

      $worker_build_threads{$worker_pid}= $mtr_build_thread;
      $worker_full_ids{$worker_pid}= $test_id;
      $worker_start_times{$worker_pid}= time();
      say("Worker for test $test_id has been started with pid $worker_pid to execute the command:", "\t$cmd");
      return 0;
  } elsif (defined $worker_pid) {
      system("cd $ENV{RQG_HOME}; $cmd");
      my $exitcode= $?>>8;
      system("mv $workdir/current1_1 $logdir/${test_id}_vardir");
      system("mv $workdir/trial1.log $logdir/${test_id}_trial.log");

      git_pull($ENV{RQG_HOME});
      system("SERVER_BRANCH=$branch_to_run SERVER_REVNO=$server_revno TEST_ALIAS=$test_alias TEST_ID=$test_id LOGDIR=$logdir $scripts_location/postmortem.sh > $logdir/${test_id}_postmortem 2>&1");
      system("rm -rf $logdir/${test_id}");
      exit $exitcode;
  } else {
      say("ERROR: Could not fork for the test job!");
      return 1;
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
