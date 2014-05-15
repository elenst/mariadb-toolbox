# Find a revision with which a failure was fixed/introduced.
# The script is expected to be run from <basedir>/mysql-test foloder. 
# It will revert to all revisions going backwards from $first, 
# or forward from $last, one by one, 
# run the given test and check the result.
#
# The test is expected to pass until we reach a "bad" revision,
#   or to fail until we reach a "good" revision.
#

use Getopt::Long;
use Cwd;
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
my $step = 1;
my $direction = BACKWARDS;
my $goal = FIXING_REVISION;

GetOptions (    
	"testcase=s"	=> \$testcase,
	"first=s"		=> \$first,
	"step=i"	   	=> \$step,
	"options=s"		=> \$options,
	"direction=s"	=> \$direction,
	"goal=s"			=> \$goal,
);

unless (-e 'mysql-test-run.pl') {
	print "\nERROR: wrong starting point, cd to <basedir>/mysql-test\n\n";
	exit(1);
}

unless (defined $testcase) {
	print "ERROR: test case is not defined\n";
	exit(1);
}

if ($direction =~ /^b/i) {
	$direction = BACKWARDS;
} elsif ($direction =~ /^f/i) {
	$direction = FORWARD;
}

unless ($direction == BACKWARDS or $direction == FORWARD) {
	print "ERROR: unknown direction. Valid values: -1, backwards, 1, forward\n";
	exit(1);
}

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
	print "ERROR: starting revision is specified incorrectly\n";
	exit(1);
}

if ($first == -1) {
	$first = `bzr revno`;
	chomp $first;
	unless ($first and $first =~ /^\d+$/) {
		print "ERROR: could not detect the starting revision: $first\n";
		exit(1);
	}
}
	
my $goal_text = ($goal == FIXING_REVISION ? 'fixing' : 'guilty');
my $direction_text = ($direction == FORWARD ? 'forward' : 'backwards');
my %result_text = (0 => 'PASSED', 1 => 'FAILED');

my $revno = $first;
my $cwd = cwd();
my $prev_revno = $revno;

my ( $first_result, $res, $prev_res );

$step *= $direction; # for backwards, step is negative; for forward -- positive


print "\n\n     We will go $direction_text starting from revno $first with the initial step $step \
     to find the $goal_text revision for testcase $testcase with options '$options'\n\n";

while ($step) 
{
	while ($revno) 
	{
		print "\n\n****************** Trying revno $revno ... ***********************\n\n";
		print "Running bzr revert -r $revno...\n";
		system("cd $cwd/.. && bzr revert -r $revno > build_$revno.log 2>&1");
		if ($? > 0) {
			print "\nbzr revert -r $revno failed, finishing...\n";
			$revno = undef;
			last;
		}
		print "Bzr revert succeeded, building...\n";
		system("cd $cwd/.. && make -j3 >> build_$revno.log 2>&1");
		if ($? > 0 and -e "$cwd/../last_build") {
			print "\nWARNING: Build failed, trying to rebuild using $cwd/../last_build...\n";
			system("cd $cwd/.. && . ./last_build >> build_$revno.log 2>&1");
		}
		if ($? > 0) {
			print "\nWARNING: Build failed, going to the next revision...\n\n";
		}
		else {
			print "\nBuild succeeded, running the test...\n\n";
			system("cd $cwd && perl ./mtr $testcase $options");
			$res = ($? ? FAIL : PASS); # Normalize -- we don't care which error code it produces, only care if 0 or not 0

			unless (defined $first_result) {

				$first_result = $res;

				# Rule out senseless combinations, when there is nothing to look for:
				# GUILTY + BACKWARDS + first pass => doesn't make sense
				# GUILTY + BACKWARDS + first fail => OK, look for pass
				# GUILTY + FORWARD   + first pass => OK, look for fail
				# GUILTY + FORWARD   + first fail => doesn't make sense
				# FIXING + BACKWARDS + first pass => OK, look for fail
				# FIXING + BACKWARDS + first fail => doesn't make sense
				# FIXING + FORWARD   + first pass => doesn't make sense
				# FIXING + FORWARD   + first fail => OK, look for pass

				if (  ( $direction == BACKWARDS and $goal != $first_result )
					or ( $direction == FORWARD   and $goal == $first_result ) ) 
				{
					print "The first test run (on revno $revno) $result_text{$first_result}, \
while we want $goal_text revision going $direction_text. \
There is nothing to look for.\n\n";
					exit(1);
				}
				
			}

			print "\n\n****************** Test $result_text{$first_result} on revno $revno ***********************\n\n";
			if ($res != $first_result) { 
				last;
			}
			$prev_revno = $revno;
			$prev_res = $res;
		}

		if ($revno =~ /^\d+$/) {
			$revno += $step;
		}
		elsif ($revno =~ /^([\d\.]+\.)(\d+)$/) {
			if ($2 == 0) {
				$revno = 0;
			}
			else {
				$revno = $1 . ($2+$step);
			}
		}
		else {
			print "ERROR: could not recognize format of revno: $revno\n";
			last;
		}
	}

	last unless ($revno); # We didn't find what we were looking for, no reason to play with the step
	last if abs($step) == 1; 

	# If the previous search was successfull, reduce the step
	$revno = $prev_revno;	
	$step = (abs($step) > 100 ? 10*$direction : 1*$direction );
}

if ($revno) {
	print "\nThe first checked revision where the test $result_text{$res}: $revno. \n";
	print "\nThe last checked revision where the test $result_text{$prev_res}: $prev_revno. \n";
} 
else {
	print "\nAll checked revisions $result_text{$first_result}\n\n";
}


