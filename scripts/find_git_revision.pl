# Find a revision with which a failure was fixed/introduced.
# The script is expected to be run from <basedir>/mysql-test foloder. 
# It will revert to all revisions going backwards from $first, 
# run the given test and check the result.
#
# The test is expected to pass until we reach a "bad" revision,
#   or to fail until we reach a "good" revision.
#

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

my $first = -1;
my $testcase;
my $options;
my $step = 10;
my $direction = BACKWARDS;
my $goal = GUILTY_REVISION;
my $debug = 0;
my $test_cmd;
my $failure_output = '';

GetOptions (    
	"testcase=s"	=> \$testcase,
	"first=s"		=> \$first,
	"step=i"	   	=> \$step,
	"options=s"		=> \$options,
#	"direction=s"	=> \$direction,
	"goal=s"			=> \$goal,
	"cmd=s"			=> \$test_cmd,
	"failure-output=s" => \$failure_output,
	"failure_output=s" => \$failure_output,
	"output=s"		=> \$failure_output
);

unless (-e 'VERSION') {
	print "\nERROR: wrong starting point, cd to <basedir>\n\n";
	exit(1);
}

if (defined $testcase and defined $test_cmd) {
	print "ERROR: cannot define both testcase and test_cmd\n";
	exit(1);
}
elsif (not defined $testcase and not defined $test_cmd) {
	print "ERROR: must define either testcase or test_cmd\n";
	exit(1);
}

if (defined $testcase) {
	$test_cmd = "cd mysql-test ; perl mysql-test-run.pl $testcase $options";
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

unless ($first) {
	$first = get_commit();
	unless ( $first and $first ne '-1' ) {
		print "ERROR: starting revision is specified incorrectly\n";
		exit(1);
	}
}

my $goal_text = ($goal == FIXING_REVISION ? 'fixing' : 'guilty');
my $direction_text = 'backwards';
my %result_text = (0 => 'PASSED', 1 => 'FAILED');

my $commit = $first;
my $cwd = cwd();
my $pos_from_start = 0;
my $prev_commit = $commit;

my ( $first_result, $res, $prev_res );

print "\n\n     We will go $direction_text starting from revision $commit with the initial step $step \
     to find the $goal_text revision for testcase $testcase with options '$options'\n\n";

STEP:
while ($step) {
	print "\n\n================== Step is now $step ==================\n\n";

REVISION:
	while ($commit) {
		print "\n\n****************** Trying revision $commit (~$pos_from_start from starting point) ***********************\n\n";
		my $cmd = "cd $cwd && pwd && git checkout -f $commit && git submodule update > build_$commit.log 2>&1";
		print "Running\n   $cmd\n";
		system($cmd);
		if ($? > 0) {
			print "\ngit checkout -f $commit failed, finishing...\n";
			$commit = undef;
			last REVISION;
		}
		$cmd = "cd $cwd && pwd && make -j3 >> build_$commit.log 2>&1";
		print "Git checkout -f succeeded, building...\n   $cmd\n";
		system($cmd);
		if ($? > 0 and -e "$cwd/last_build") {
			$cmd = "cd $cwd/.. && pwd && rm -f CMakeCache.txt && . ./last_build >> build_$commit.log 2>&1";
			print "\nWARNING: Build failed, trying to do a clean build using $cwd/last_build...\n   $cmd\n";
			system($cmd);
		}
		if ($? > 0) {
			print "\nWARNING: Build failed, skipping the revision...\n\n";
			$commit = get_commit($commit,1);
			$pos_from_start += 1;
		}
		else {
			$cmd = $test_cmd;
			print "\nBuild succeeded, running the test...\n  $cmd\n\n";
			my $out = readpipe("$cmd");
			$res = ($? ? FAIL : PASS); # Normalize -- we don't care which error code it produces, only care if 0 or not 0
			if ( $failure_output && $out =~ /$failure_output/ ) {
				print "\nTest output matches the pattern\n";
			}
			elsif ($failure_output) {
				print "\nTest output does not match the pattern:\n";
                print "Output is:\n", $out, "\n";
                print "and pattern is: $failure_output\n";
				$res = PASS;
			}

			unless (defined $first_result) {

				$first_result = $res;

				# Rule out senseless combinations, when there is nothing to look for:
				# GUILTY + first pass => doesn't make sense
				# GUILTY + first fail => OK, look for pass
				# FIXING + first pass => OK, look for fail
				# FIXING + first fail => doesn't make sense

				if ( $goal != $first_result ) {
					print "The first test run (on commit $commit) $result_text{$first_result}, \n"
					. "while we want $goal_text revision going $direction_text. \n"
					. "There is nothing to look for.\n\n";
					exit(1);
				}
			
			}

			print "\n\n****************** Test $result_text{$res} on commit $commit ***********************\n\n";

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
	$step = ($step > 100 ? 10 : 1);
}

if ($commit and $res != $goal) {
	print "\nThe last checked revision where the test $result_text{$res}: $commit. \n";
	print "\nThe first checked revision where the test $result_text{$goal}: $prev_commit. \n";
} 
else {
	print "\nAll checked revisions $result_text{$first_result}\n\n";
}


sub get_commit {
	my ($from,$depth) = @_;

	my $rev = $from || '';
	if ($depth) {
		foreach (1..$depth) { $rev .= '^' };
	}
	my $commit = -1;

	open(GIT_LOG, "git log -1 $rev |") || die "Could not run git log: $!\n";
	while (<GIT_LOG>) {
		if( /^commit (\S+)/ ) {
			$commit = $1;
			last;
		}
	}
	close(GIT_LOG);
	return $commit;
}

sub debug {
	print @_ if $debug;
}
