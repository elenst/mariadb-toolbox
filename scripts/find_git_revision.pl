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

my $nCPU=`grep -c processor /proc/cpuinfo`;
chomp $nCPU;

my @commits_to_bisect= ();
my $build_options= '-DCMAKE_BUILD_TYPE=Debug -DMYSQL_MAINTAINER_MODE=OFF -DCMAKE_C_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS="-std=gnu++98" -DWITH_SSL=bundled -DPLUGIN_TOKUDB=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_XPAND=NO -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPHINX=NO -DPLUGIN_SPIDER=NO -DPLUGIN_MROONGA=NO -DPLUGIN_FEDERATEDX=NO -DPLUGIN_CONNECT=NO -DPLUGIN_FEDERATED=NO -DWITH_MARIABACKUP=OFF '.$cmake_options.($asan ? ' -DWITH_ASAN=YES' : '');

unless (-e 'VERSION') {
	print "\nERROR: wrong starting point, cd to <basedir>\n\n";
	exit(1);
}
my $cwd = cwd();

if (defined $testcase and defined $test_cmd) {
	print "ERROR: cannot define both testcase and test_cmd\n";
	exit(1);
}
elsif (not defined $testcase and not defined $test_cmd) {
	print "ERROR: must define either testcase or test_cmd\n";
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
#	print "ERROR: unknown direction. Valid values: -1, backwards, 1, forward\n";
#	exit(1);
#}

if ($goal =~ /^(b|g)/i) {
	$goal = GUILTY_REVISION;
} elsif ($goal =~ /^f/i) {
	$goal = FIXING_REVISION;
}

unless ($goal == FIXING_REVISION or $goal == GUILTY_REVISION) {
	print "ERROR: unknown goal. Valid values: 1, guilty, breaking, 0, fixing\n";
	exit(1);
}

$first = get_commit($first);
unless ( $first and $first ne '-1' ) {
  print "ERROR: starting revision is specified incorrectly\n";
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
  print "\nNumber of commits to bisect: ".scalar(@commits_to_bisect)."\n\n";
}

my $goal_text = ($goal == FIXING_REVISION ? 'fixing' : 'guilty');
my $direction_text = 'backwards';
my %result_text = (0 => 'PASSED', 1 => 'FAILED');

my $commit = $first;
my $pos_from_start = 0;
my $prev_commit = $commit;

system("cd $cwd && date > bisect.log 2>&1");

first_run($commit);

scalar(@commits_to_bisect) ? bisect() : traverse();

sub bisect {
  my ($res, $first_rev, $last_rev);
  # We already know that the first commit meets the goal,
  # now we need to check that the last commit returns a different result,
  # otherwise there is nothing to look for
  print "Checking that the last commit $commits_to_bisect[$#commits_to_bisect] differs from the first one\n\n";
  $res= run_step($commits_to_bisect[$#commits_to_bisect]);
  if (not defined $res) {
    die "FATAL ERROR: Could not build the last revision $last\n\n";
  } elsif ($res == $goal) {
    die "FATAL ERROR: The last revision $commits_to_bisect[$#commits_to_bisect] also $result_text{$res},\nso there is nothing to look for.\n\n";
  }
  my @remaining_revisions= @commits_to_bisect;
  # $first element should always be the commit which meets the $goal,
  # and $last always the latest revision found so far which does not.
  # Bisect continues until there are any buildable revisions between these two
  $first_rev= shift @remaining_revisions;
  $last_rev= pop @remaining_revisions;
  while (scalar(@remaining_revisions)) {
    print "Remaining revisions to bisect: ".scalar(@remaining_revisions)."\n\n";
    my $new_ind= int(scalar(@remaining_revisions)/2);
    $res= run_step($remaining_revisions[$new_ind]);
    if (not defined $res) {
      print "Build of commit $remaining_revisions[$new_ind] failed, we are excluding the revision from further search\n\n";
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

  print "\n\n     We will go $direction_text starting from revision $commit with the initial step $step \
       to find the $goal_text revision for testcase $testcase with options '$options'\n\n";

  STEP:
  while ($step) {
    print "\n\n================== Step is now $step ==================\n\n";

  REVISION:
    while ($commit) {
      print "\n\n****************** Trying revision $commit (~$pos_from_start from starting point) ***********************\n\n";
      unless (checkout($commit)) {
        print "Finishing...\n";
        last REVISION;
      }

      if (build()) {
        print "\nWARNING: Build failed, skipping the revision...\n\n";
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
    print "\nAll checked revisions $result_text{$res}\n\n";
  }
}

sub report_result {
  my ($first_rev, $last_rev)= @_;
  print "\nThe earliest checked revision which produces the current result ($result_text{$goal}): $first_rev. \n";
  print "\nThe latest checked revision where the result differs: $last_rev. \n\n";
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
  print "Checking that the first commit $commit meets the goal ($result_text{$goal})\n\n";
  my $res= run_step($commit);
  die "FATAL ERROR: Could not build the first revision\n\n" unless defined $res;
  if ($goal != $res) {
    die "The first test run (on commit $commit) $result_text{$res}, \n"
    . "while we want $goal_text revision going $direction_text. \n"
    . "There is nothing to look for.\n\n";
  }
}

sub run_step {
  my $commit= shift;
  my $res;
  checkout($commit);

  if (build() != PASS) {
    print "\nWARNING: Build failed\n\n";
    return undef;
  }
  else {
    $res= run_test();
    print "\n\n****************** Test $result_text{$res} on commit $commit ***********************\n\n";
  }
  return $res;
}

sub checkout {
  my $commit= shift;
  my $cmd = "cd $cwd && pwd && git checkout -f $commit && git submodule update >> bisect.log 2>&1";
  print "Running\n   $cmd\n";
  system($cmd);
  if ($? > 0) {
    die "FATAL ERROR: Could not checkout commit $commit\n\n";
  }
  return $commit;
}

sub build {
  my $cmd = "cd $cwd && pwd && make -j$nCPU >> bisect.log 2>&1";
  print "Git checkout -f succeeded, building...\n   $cmd\n";
  system($cmd);
#  if ($? > 0) {
#    print "\nWARNING: Build failed, trying to do a clean build\n";
#    system("git clean -ddffxx -e mysql-test -e bisect.log >> bisect.log 2>&1");
#    system("git submodule foreach --recursive git clean -ddffxx >> bisect.log 2>&1");
#    system("cmake . $build_options >> bisect.log 2>&1");
#    if ($?) {
#      print "cmake failed, no more attempts to build\n";
#      return $? >> 8;
#    }
#    system("make -j$nCPU >> bisect.log 2>&1");
#  }
  return $? >> 8;
}

sub run_test {
  print "\nBuild succeeded, running the test...\n  $test_cmd\n\n";
  my $out = readpipe("$test_cmd");
  if (open(BISECT_LOG,">>$cwd/bisect.log")) {
    print BISECT_LOG $out;
    close(BISECT_LOG);
  } else {
    print "ERROR: couldn't open bisect.log for writing: $!\n";
  }
  # If result isn't 1 (FAIL) or 0 (PASS), something is very wrong,
  # for example, the test does not exist. No point to continume
  my $res= ($? >> 8);
  if ($res != FAIL and $res != PASS) {
    die "FATAL ERROR: Test run finished with an unexpected result: $res\n\n";
  }
  if ( $failure_output && $out =~ /$failure_output/ ) {
    print "\nTest output matches the pattern\n";
  }
  elsif ($failure_output) {
    print "\nTest output does not match the pattern:\n";
            print "Output is:\n", $out, "\n";
            print "and pattern is: $failure_output\n";
    $res = PASS;
  }
  elsif ($verbose) {
    print "VERBOSE MODE ON. Whole test output:\n-----------------------------\n$out\n-----------------------------\n\n";
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
	print @_ if $debug;
}
