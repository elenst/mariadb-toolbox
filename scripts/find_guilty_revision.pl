# Find a revision with which a failure started happening.
# The script is expected to be run from <basedir>/mysql-test foloder. 
# It will revert to all revisions going backwards from $first, one by one, 
# run the given test and check the result.
#
# The test is expected to fail until we reach a "good" revision. 

use Getopt::Long;
use strict;

my $first = -1;
my $testcase;
my $options;

GetOptions (    
	"testcase=s"	=> \$testcase,
	"first=s"		=> \$first,
	"options=s"		=> \$options,
);

unless (defined $testcase) {
	print "ERROR: test case is not defined\n";
	exit(1);
}

my $revno = $first;

while ($revno) {
	print "\n\n****************** Trying revno $revno ... ***********************\n\n";
	system("cd .. && bzr revert -r $revno && make -j3 && cd - && perl ./mtr $testcase $options");
	print "\n\n****************** Test " . ($? ? "failed " : "passed " ) . "on revno $revno ***********************\n\n";

	if ($? == 0) { 
		last;
	}
	if ($revno =~ /^\d+$/) {
		$revno--;
	}
	elsif ($revno =~ /^([\d\.]+\.)(\d+)$/) {
		if ($2 == 0) {
			$revno = 0;
		}
		else {
			$revno = $1 . ($2-1);
		}
	}
	else {
		print "ERROR: could not recognize format of revno: $revno\n";
	}
}

if ($revno) {
	print "\nFound the last unaffected revision: $revno\n\n";
} 
else {
	print "\nAll checked revisions failed\n\n";
}


