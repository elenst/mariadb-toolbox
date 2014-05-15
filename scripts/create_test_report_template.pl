# Creates a short change log between $first and $last revisions 
# on the branch in the current directory. 
# The change log is one-line-per-revision:
# revno <tab> committer <tab> short description
# Suitable for creating a spreadsheet etc.

use Getopt::Long;

use strict;
my ($first, $last) = ( 0, 10000000000000 );

GetOptions(
	'first=i' => \$first,
	'last=i' => \$last,
);

open( BZRLOG, "bzr log | " ) || die "Could not run bzr log: $!\n";

print "||revno||committer||message||(i)||notes||\n";
my $line;
while (<BZRLOG>) 
{
	if (/^revno:\s+(\d+)/) {
		last if $1 < $first;
		next if $1 > $last;
		$line = "|$1|";
		
	}
	elsif (/^committer:\s+([^\<]+)/ and $line ) {
		my $committer = $1;
		chomp $committer;
		$line .= "$committer|";
	}
	elsif (/^message:/ and $line ) {
		my $msg = <BZRLOG>;
		chomp $msg;
		$msg =~ s/^\s*//;
		$line .= $msg;
		print "$line|||\n";
		$line = '';
	}
}
close(BZRLOG);

