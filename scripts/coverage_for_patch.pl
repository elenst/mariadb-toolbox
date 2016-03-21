#!/bin/perl

# Present coverage info for a code patch

# Collects gcov data from the basedir into the info file,
# takes bzr diff with the previous revision (or with the revision given as the 2nd argument)
# and checks the coverage for the changes

use Getopt::Long;
use strict;

my ( $basedir, $diffile, $prev_revno, @infofiles, $branch_info, $debug, $help );

my $res = &GetOptions (
	"basedir=s" => \$basedir,
	"diff-file=s" => \$diffile,
	"diff_file=s" => \$diffile,
	"difffile=s" => \$diffile,
	"prev-revno=i" => \$prev_revno,
	"prev_revno=i" => \$prev_revno,
	"prevrevno=i" => \$prev_revno,
	"lcov-info=s@" => \@infofiles,
	"lcovinfo=s@" => \@infofiles,
	"lcov_info=s@" => \@infofiles,
	"debug" => \$debug,
	"branch_info" => \$branch_info,
	"branch-info" => \$branch_info,
	"help" => \$help,
);

if ( $help )
{
	print "\nThe script produces an lcov summary of gcov data stored in the basedir\n";
	print "(or uses already existing lcov info file), and extracts the coverage data related \n";
	print "to the code patch or diff\n";
	print "\nUsage: perl $0 <options>\n\n";
	print "\t--basedir=<path>: source code work tree \n\t\tneeded if there is no lcov info file or patch/diff file yet;\n";
	print "\t\tit is also used to remove the prefix from absolute paths in lcov.info\n";
	print "\t--diff-file=<path>: a patch or bzr diff file; \n\t\tif there is no such file yet, it will be generated by bzr diff\n";
	print "\t--prev-revno=<bzr revision>: a revision to compare with the work tree; \n\t\t-2 by default (meaning last but one)\n";
	print "\t--lcov-info=<path>: a coverage summary file produced by lcov; \n\t\tif there is no such file yet, it will be generated\n";
	print "\t--branch-info: include branch coverage info into the report \n\t\t(FALSE by default)\n";
	print "\t--debug: script debug output\n";
	print "\t--help: print this help and exit\n";
	print "\n";
	exit;
}

if ( not defined $basedir )
{
	print STDERR "WARNING: Basedir is not provided, it's possible that paths in lcov output won't be recognized\n";
}

if ( not defined $basedir and not @infofiles )
{
	print STDERR "ERROR: Either --basedir or --lcov-info should be provided!\n";
	exit 1;
}
if ( ! defined $basedir and ! defined $diffile )
{
	print STDERR "ERROR: Either --basedir or --diff-file should be provided!\n";
	exit 1;
}

if ( $diffile and not -e "$diffile" )
{
	print STDERR "ERROR: $diffile does not exist\n";
	exit 1;
}
foreach my $if ( @infofiles )
{
	unless ( -e "$if" ) {
		print STDERR "ERROR: $if does not exist\n";
		exit 1;
	}
} 

unless ( $diffile ) 
{
	$diffile = "/tmp/test-bzr-diff";
	$prev_revno ||= -2; # -2 means the previous revision
	chdir( $basedir );
	system( "bzr diff --diff-options=\"-U 0\" -r $prev_revno > $diffile" );
}

unless ( @infofiles )
{
	my $infofile = "/tmp/test-lcov-info";
	system( "lcov --directory $basedir --capture --output-file $infofile > /dev/null" );
	if ($?) {
		print STDERR "ERROR: failed to execute lcov, check that it's on the PATH and that $infofile is writable\n";
		exit 1;
	}
	push @infofiles, $infofile;
}



# Hash key is a file name
# Hash value is an array of code lines (unchanged or new)
my %fragments = ();

# Hash key is <file name>:<lineno>
# Hash value is the total count of hits
# (as the file might be present in infofiles more than once)
my %counts = ();

# Hash key is <file name>:<lineno>
# Hash value is an array of hits per branch (array index is the branch number)
my %branches = ();


open( PATCH, "<$diffile" ) || die "Could not open $diffile for reading\n";

while ( my $line = <PATCH> )
{
	# Find the next modified or added file
	if ( $line =~ /^===\s(?:added|modified)\sfile\s\'?([^']+)\'?/ 
			or $line =~ /^diff\s--git\sa\/([^'\s]+)/ )
	{
		my $f = $1;
		next if $f =~ /^mysql-test/ ; # No need to process MTR stuff
		debug( "File: $f\n" );
		do {
			# index ... (for git)			
			# --- <old file>
			# +++ <new file>
			# @@ -<old pos>,<old length> +<new pos>,<new length> @@
			$line = <PATCH>;
		} until ( $line =~ /^\@\@\s\-\d+,\d+\s\+(\d+),(\d+)/ );

		while ( $line =~ /^\@\@\s\-\d+,\d+\s\+(\d+),(\d+)/ )
		{
			my ( $start, $length ) = ( $1, $2 );
			my $l = $start;
			debug( "Start: $start Length: $length\n" );
			while ($l < $start + $length)
			{
				$line = <PATCH>;
				next if $line =~ /^-/;
				chomp $line;
				# We will only define those elements of @{$fragments{<filename>}} 
				# which lines we are interested in. E.g. if our first fragment is 10,2
				# then $fragments{$f}[10] and $fragments{$f}[11] will be defined, but previous 10 elements won't be
				${$fragments{$f}}[$l] = $line;
				$counts{"$f:$l"} = '';
				$l++;
			}
			$line = <PATCH>;
		}
	}
}

close( PATCH );

debug( "Patch processed\n" );

foreach my $infofile ( @infofiles ) 
{
	open( LCOV, "<$infofile" ) || die "Could not open $infofile for reading\n";

	while ( my $line = <LCOV> )
	{
		if ( $line =~ /^SF:(.*)/ ) {
			my $f = $1;
			$f =~ s/^$basedir\/?//;

			next unless defined $fragments{$f};
			debug( "In lcov: file $f\n" );

			if ( $branch_info ) {
				do {
					$line = <LCOV>;
				}
				until ( $line =~ /^BRDA/ or $line =~ /^BRF/ or $line =~ /^DA/ or $line =~ /end_of_record/ );
				while ( $line =~ /^BRDA:(\d+),\d+,(\d+),([-\d]+)/ )
				{
					my ( $l, $b, $hits ) = ( $1, $2, $3 );
					$hits = 0 if $hits eq '-';
	#				debug( "In lcov: $. : line $l, branch $b, hits $hits\n" );
					debug( "In lcov: $. : line $l, branch $b, old hits " . ${$branches{"$f:$l"}}[$b] . " current hits $hits new hits " . (${$branches{"$f:$l"}}[$b]  + $hits ) . "\n" );
					${$branches{"$f:$l"}}[$b] = ( ${$branches{"$f:$l"}}[$b] ? ${$branches{"$f:$l"}}[$b] + $hits : $hits );
					$line = <LCOV>;
				}
			}

			do {
				$line = <LCOV>;
			# If the file doesn't contain any instrumented lines, DA might not exist (?)
			} until ( $line =~ /^DA/ or $line =~ /^LF/ or $line =~ /end_of_record/ );
			debug( "In lcov: line $line\n" );

			# Don't know why it has negative hits, but sometimes it does
			while ( $line =~ /^DA:(\d+),([-\d]+)/ )
			{
				my ( $l, $hits ) = ( $1, $2 );
	#			debug( "In lcov: line $l, hits $hits\n" );
				debug( "In lcov: line $l, old hits " . $counts{"$f:$l"}. " current hits $hits new hits " . ( $counts{"$f:$l"} + $hits ) . "\n" );
				$counts{"$f:$l"} = ( $counts{"$f:$l"} ? $counts{"$f:$l"} + $hits : $hits );
				debug( "In lcov: line $l, real new hits " . $counts{"$f:$l"} . "\n" );
				$line = <LCOV>;
			}
		}
	}

	close( LCOV );
}

my @zero_counts = ();
my @zero_branches = ();
my $total_lines = 0;
my $total_branches = 0;
my $zero_lines = 0;
my $zero_branches = 0;

foreach my $f ( sort keys %fragments ) 
{
	my @zero_c = ();
	my @zero_b = ();
	print "\n===== File: $f =====\n";
	my $gap = 0;
	foreach my $ln ( 0 .. $#{$fragments{$f}} ) {
		unless ( defined ${$fragments{$f}}[$ln] ) {
			print "\n" unless $gap;
			$gap = 1;
			next;
		}
		$gap = 0;
		print sprintf("%7s : %13s : ", $ln, $counts{"$f:$ln"} ) . ${$fragments{$f}}[$ln] . "\n";
		if (${$fragments{$f}}[$ln] =~ /^\+/) {
			$total_lines++;
			if ( $counts{"$f:$ln"} eq '0' ) {
				push @zero_c, sprintf("%7s : ", $ln ) . ${$fragments{$f}}[$ln];
				$zero_lines++;
			}
		}
		if ( defined $branches{"$f:$ln"} ) {
			foreach my $b ( 0 .. $#{$branches{"$f:$ln"}} ) {
				next unless defined ${$branches{"$f:$ln"}}[$b];
				print sprintf( "%7s b%2d: %-7s   ::\n", ':', $b, ${$branches{"$f:$ln"}}[$b] );	
				if ( ${$fragments{$f}}[$ln] =~ /^\+/ ) {
					$total_branches++;
					if ( ${$branches{"$f:$ln"}}[$b] eq '0' ) 
					{
						push @zero_b, sprintf("b%2d: %7s : ", $b, $ln ) . ${$fragments{$f}}[$ln];
						$zero_branches++;
					}
				}
			}
		}
	}
	if ( @zero_c ) {
		push @zero_counts, ( "\n$f:", @zero_c );
	}
	if ( @zero_b ) {
		push @zero_branches, ( "\n$f:", @zero_b );
	}
}
print "\n";

if ( @zero_counts ) {
	print STDERR "\nLines with zero coverage ($zero_lines/$total_lines):\n";
	foreach ( @zero_counts ) { print STDERR $_, "\n" };
}
print STDERR "\n";

if ( @zero_branches ) {
	print STDERR "\nLines with zero branches ($zero_branches/$total_branches):\n";
	foreach ( @zero_branches ) { print STDERR $_, "\n" };
}
print STDERR "\n";

sub debug {
	print STDERR @_ if $debug;
}
