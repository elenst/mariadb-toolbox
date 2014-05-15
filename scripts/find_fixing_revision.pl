# Find a revision with which a failure was fixed.
# The script is expected to be run from <basedir>/mysql-test foloder. 
# It will revert to all revisions going backwards from $first, one by one, 
# run the given test and check the result.
#
# The test is expected to pass until we reach a "bad" revision. 
#
# This is a twin/opposite for find_guilty_revision.pl

use Getopt::Long;
use Cwd;
use strict;

my $first = -1;
my $testcase;
my $options;
my $step = 1;
my $direction = -1; # -1 backwards, 1 forward 

GetOptions (    
	"testcase=s"	=> \$testcase,
	"first=s"		=> \$first,
	"step=i"	   	=> \$step,
	"options=s"		=> \$options,
	"direction=s"	=> \$direction,
);

unless (defined $testcase) {
	print "ERROR: test case is not defined\n";
	exit(1);
}

if ($direction =~ /b/i) {
	$direction = -1;
} elsif ($direction =~ /f/i) {
	$direction = 1;
}

unless ($direction == -1 or $direction == 1) {
	print "ERROR: unknown direction. Valid values: -1, backwards, 1, forward\n";
	exit(1);
}

my $revno = $first;
my $cwd = cwd();
my $prev_revno = $revno;

my $first_result;

$step *= $direction;

while ($revno) {
	print "\n\n****************** Trying revno $revno ... ***********************\n\n";
	system("cd $cwd/.. && bzr revert -r $revno");
	if ($? > 0) {
		print "\nbzr revert -r $revno failed, finishing\n";
		$revno = 0;
		last;
	}
	system("cd $cwd/.. && make -j3 > build_$revno.log 2>&1");
	if ($? == 0) {
		print "\nBuild succeeded, running the test..\n\n";
		system("cd $cwd && perl ./mtr $testcase $options");
		unless (defined $first_result) {
			$first_result = $?;
		}
		print "\n\n****************** Test " . ($? ? "failed " : "passed " ) . "on revno $revno ***********************\n\n";
		if ($? != $first_result) { 
			last;
		}
	}
	else { 
		print "\nBuild failed, going to the next revision...\n\n";
	}
	$prev_revno = $revno;
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
	}
}

if ($revno) {
	print "\nFound the last affected revision: $revno. The first checked(!) unaffected revision: $prev_revno\n\n";
} 
else {
	print "\nAll checked revisions passed\n\n";
}


