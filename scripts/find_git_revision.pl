#!/usr/bin/perl

# Copyright (c) 2016, 2023, Elena Stepanova and MariaDB
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1335  USA

########################################################################
# Find a revision with which a failure was fixed/introduced.
# The script is expected to be run from <basedir> folder.
#
# The test is expected to pass until we reach a "bad" revision,
#   or to fail until we reach a "good" revision.
#
# The script goes backwards, so $first revision is the latest,
# and $last is the earliest.
# If --first is not specified, it is set to the current revision.
# If --last is not specified, the search goes backwards in steps of
# --steps=N revisions. If --last is specified, the actual bisect
# is performed, where contents of merges is skipped.
########################################################################


use Getopt::Long;
use Cwd;
use List::Util qw(min);
use strict;

use constant BACKWARDS => -1; # backwards, -1
use constant FORWARD => 1;    # forward, 1
use constant GUILTY_REVISION => 1;  # guilty, breaking, 1
use constant FIXING_REVISION => 0;   # fixing, 0
use constant PASS => 0;
use constant FAIL => 1;

my $first = undef;
my $last = undef;
my $testcase;
my $options;
my $step = 10;
my $direction = BACKWARDS;
my $goal = GUILTY_REVISION;
my $debug = 0;
my $test_cmd;
my $failure_output = '';
my $cmake_options = '';
my $asan;
my $verbose= 0;

GetOptions (    
	"testcase=s"	=> \$testcase,
	"first=s"		=> \$first,
	"last=s"		=> \$last,
	"step=i"	   	=> \$step,
	"options=s"		=> \$options,
#	"direction=s"	=> \$direction,
	"goal=s"			=> \$goal,
	"cmd=s"			=> \$test_cmd,
	"failure-output=s" => \$failure_output,
	"failure_output=s" => \$failure_output,
	"output:s"		=> \$failure_output,
  "cmake_options|cmake-options=s" => \$cmake_options,
  "asan|with_asan|with-asan" => \$asan,
  "--verbose"  => \$verbose,
);

sub say {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  foreach (@_) {
    print sprintf("%04d-%02d-%02d %02d:%02d:%02d %s\n", $year+1900, $mon+1 ,$mday ,$hour, $min, $sec, $_);
  }
}

my $nCPU=`grep -c processor /proc/cpuinfo`;
chomp $nCPU;

my @commits_to_bisect= ();
my $build_options= '-DCMAKE_BUILD_TYPE=Debug -DMYSQL_MAINTAINER_MODE=OFF -DCMAKE_C_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS="-std=gnu++98" -DWITH_SSL=bundled -DPLUGIN_TOKUDB=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_XPAND=NO -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPHINX=NO -DPLUGIN_SPIDER=NO -DPLUGIN_MROONGA=NO -DPLUGIN_FEDERATEDX=NO -DPLUGIN_CONNECT=NO -DPLUGIN_FEDERATED=NO -DWITH_MARIABACKUP=OFF '.$cmake_options.($asan ? ' -DWITH_ASAN=YES' : '');

unless (-e 'VERSION') {
	say "ERROR: wrong starting point, cd to <basedir>";
	exit(1);
}
my $cwd = cwd();

if (defined $testcase and defined $test_cmd) {
	say "ERROR: cannot define both testcase and test_cmd";
	exit(1);
}
elsif (not defined $testcase and not defined $test_cmd) {
	say "ERROR: must define either testcase or test_cmd";
	exit(1);
}
if (defined $testcase) {
  $test_cmd = "cd $cwd/mysql-test ; perl mysql-test-run.pl $testcase $options";
}

#if ($direction =~ /^b/i) {
#	$direction = BACKWARDS;
#} elsif ($direction =~ /^f/i) {
#	$direction = FORWARD;
#}

#unless ($direction == BACKWARDS or $direction == FORWARD) {
#	say "ERROR: unknown direction. Valid values: -1, backwards, 1, forward";
#	exit(1);
#}

if ($goal =~ /^(b|g)/i) {
	$goal = GUILTY_REVISION;
} elsif ($goal =~ /^f/i) {
	$goal = FIXING_REVISION;
}

unless ($goal == FIXING_REVISION or $goal == GUILTY_REVISION) {
	say "ERROR: unknown goal. Valid values: 1, guilty, breaking, 0, fixing";
	exit(1);
}

$first = get_commit($first);
unless ( $first and $first ne '-1' ) {
  say "ERROR: starting revision is specified incorrectly";
  exit(1);
}

if ($last) {
  my $next= $first;
  open(COMMITS, "git log --parents --topo-order --oneline ${last}^..$first |") || die "Couldn't get commits to bisect: $!\n";
  while (<COMMITS>) {
    chomp;
    next if substr($next,0,8) ne substr($_,0,8);
    push @commits_to_bisect, $next;
    last if substr($last,0,8) eq substr($next,0,8);
    /^\w+\s+(\w+)/;
    $next= $1;
  }
  close(COMMITS);
  say "\nNumber of commits to bisect: ".scalar(@commits_to_bisect)."\n";
}

my $goal_text = ($goal == FIXING_REVISION ? 'fixing' : 'guilty');
my $direction_text = 'backwards';
my %result_text = (0 => 'PASSED', 1 => 'FAILED');

my $commit = $first;
my $pos_from_start = 0;
my $prev_commit = $commit;

system("cd $cwd && date > bisect.say 2>&1");

first_run($commit);

scalar(@commits_to_bisect) ? bisect() : traverse();

sub bisect {
  my ($res, $first_rev, $last_rev);
  # We already know that the first commit meets the goal,
  # now we need to check that the last commit returns a different result,
  # otherwise there is nothing to look for
  say "Checking that the last commit $commits_to_bisect[$#commits_to_bisect] differs from the first one\n";
  $res= run_step($commits_to_bisect[$#commits_to_bisect]);
  if (not defined $res) {
    say "FATAL ERROR: Could not build the last revision $last\n";
    exit 1;
  } elsif ($res == $goal) {
    say "FATAL ERROR: The last revision $commits_to_bisect[$#commits_to_bisect] also $result_text{$res},\nso there is nothing to look for.\n";
    exit 1;
  }
  my @remaining_revisions= @commits_to_bisect;
  # $first element should always be the commit which meets the $goal,
  # and $last always the latest revision found so far which does not.
  # Bisect continues until there are any buildable revisions between these two
  $first_rev= shift @remaining_revisions;
  $last_rev= pop @remaining_revisions;
  while (scalar(@remaining_revisions)) {
    say "Remaining revisions to bisect: ".scalar(@remaining_revisions)."\n";
    my $new_ind= int(scalar(@remaining_revisions)/2);
    $res= run_step($remaining_revisions[$new_ind]);
    if (not defined $res) {
      say "Build of commit $remaining_revisions[$new_ind] failed, we are excluding the revision from further search\n";
      @remaining_revisions= (@remaining_revisions[0..$new_ind-1], @remaining_revisions[$new_ind+1..$#remaining_revisions]);
    } elsif ($res == $goal) {
      $first_rev= $remaining_revisions[$new_ind];
      @remaining_revisions= @remaining_revisions[$new_ind+1..$#remaining_revisions];
    } else {
      $last_rev= $remaining_revisions[$new_ind];
      @remaining_revisions= @remaining_revisions[0..$new_ind-1];
    }
  }
  report_result($first_rev, $last_rev);
}


sub traverse {
  my ($res, $prev_res);

  say "\n\n     We will go $direction_text starting from revision $commit with the initial step $step \
       to find the $goal_text revision for testcase $testcase with options '$options'\n";

  STEP:
  while ($step) {
    say "\n\n================== Step is now $step ==================\n";

  REVISION:
    while ($commit) {
      say "\n\n****************** Trying revision $commit (~$pos_from_start from starting point) ***********************\n";
      unless (checkout($commit)) {
        say "Finishing...";
        last REVISION;
      }

      if (build()) {
        say "\nWARNING: Build failed, skipping the revision...\n";
        $commit = get_commit($commit,1);
        $pos_from_start += 1;
      }
      else {
        $res= run_test();
        last REVISION if $res != $goal;

        $prev_res = $res;
        $prev_commit = $commit;
        $commit = get_commit($commit,$step);
        $pos_from_start += $step;
      }
    }

    # If the previous search was successfull, reduce the step. But only if there's anything to reduce
    last if $step == 1;

    # No reason to return to the commit we already checked, lets get the next one
    $commit = get_commit($prev_commit,1);
    $pos_from_start = $pos_from_start - $step + 1;
    $step = int($step/2) || 1;
  }

  if ($commit and $res != $goal) {
    report_result($prev_commit, $commit);
  } 
  else {
    say "\nAll checked revisions $result_text{$res}\n";
  }
}

sub report_result {
  my ($first_rev, $last_rev)= @_;
  say "\nThe earliest checked revision which produces the current result ($result_text{$goal}): $first_rev.";
  say "\nThe latest checked revision where the result differs: $last_rev.\n";
  system("git show $first_rev $last_rev | grep -A6 '^commit'");
}

# First run is to check that the revision we are starting from produces
# the expected result (pass or fail, depending on the goal). If it does not,
# there is no point to continue
# Rule out senseless combinations, when there is nothing to look for:
# GUILTY + first pass => doesn't make sense
# GUILTY + first fail => OK, look for pass
# FIXING + first pass => OK, look for fail
# FIXING + first fail => doesn't make sense
sub first_run {
  my $commit= shift;
  say "Checking that the first commit $commit meets the goal ($result_text{$goal})\n";
  my $res= run_step($commit);
  die "FATAL ERROR: Could not build the first revision\n\n" unless defined $res;
  if ($goal != $res) {
    say "The first test run (on commit $commit) $result_text{$res}, \n"
    . "while we want $goal_text revision going $direction_text. \n"
    . "There is nothing to look for.\n";
    exit 1;
  }
}

sub run_step {
  my $commit= shift;
  my $res;
  checkout($commit);

  if (build() != PASS) {
    say "\nWARNING: Build failed\n";
    return undef;
  }
  else {
    $res= run_test();
    say "\n\n****************** Test $result_text{$res} on commit $commit ***********************\n";
  }
  return $res;
}

sub checkout {
  my $commit= shift;
  my $cmd = "cd $cwd/libmariadb/libmariadb && git reset --hard HEAD && cd $cwd && pwd && git checkout -f $commit && git submodule update && sed -i -e 's/END()/ENDIF()/g' libmariadb/cmake/ConnectorName.cmake >> bisect.say 2>&1";
  say "Running\n   $cmd";
  system($cmd);
  if ($? > 0) {
    die "FATAL ERROR: Could not checkout commit $commit\n\n";
  }
  return $commit;
}

sub build {
  my $cmd = "cd $cwd && pwd && make -j$nCPU >> bisect.say 2>&1";
  say "Git checkout -f succeeded, building...\n   $cmd";
  system($cmd);
#  if ($? > 0) {
#    say "\nWARNING: Build failed, trying to do a clean build";
#    system("git clean -ddffxx -e mysql-test -e bisect.say >> bisect.say 2>&1");
#    system("git submodule foreach --recursive git clean -ddffxx >> bisect.say 2>&1");
#    system("cmake . $build_options >> bisect.say 2>&1");
#    if ($?) {
#      say "cmake failed, no more attempts to build";
#      return $? >> 8;
#    }
#    system("make -j$nCPU >> bisect.say 2>&1");
#  }
  return $? >> 8;
}

sub run_test {
  say "\nBuild succeeded, running the test...\n  $test_cmd\n";
  my $out = readpipe("$test_cmd");
  if (open(BISECT_LOG,">>$cwd/bisect.log")) {
    print BISECT_LOG $out;
    close(BISECT_LOG);
  } else {
    say "ERROR: couldn't open bisect.say for writing: $!";
  }
  # If result isn't 1 (FAIL) or 0 (PASS), something is very wrong,
  # for example, the test does not exist. No point to continume
  my $res= ($? >> 8);
  if ($res != FAIL and $res != PASS) {
    die "FATAL ERROR: Test run finished with an unexpected result: $res\n\n";
  }
  if ( $failure_output && $out =~ /$failure_output/ ) {
    say "\nTest output matches the pattern";
  }
  elsif ($failure_output) {
    say "\nTest output does not match the pattern:";
            say "Output is:\n", $out;
            say "and pattern is: $failure_output";
    $res = PASS;
  }
  elsif ($verbose) {
    say "VERBOSE MODE ON. Whole test output:\n-----------------------------\n$out\n-----------------------------\n";
  }
  return $res;
}

sub get_commit {
	my ($from,$depth) = @_;

	my $rev = $from || '';
	if ($depth) {
		foreach (1..$depth) { $rev .= '^' };
	}
	my $commit = `git log -1 --topo-order --oneline --pretty="%h" $rev`;
  chomp $commit;
	return $commit;
}

sub debug {
	say @_ if $debug;
}

