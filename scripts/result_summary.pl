# The script will return 1 if any output file shows exit code other than OK or MISMATCH; 
# otherwise, it will return the exit code of mismatch_filter.pl
#
# The script is supposed to be used as 
#   result_summary.pl trial*log 

use Cwd 'abs_path';
use File::Basename;
use strict;

my $path = dirname(abs_path($0));

$| = 1;
my $debug = 0;

my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

#----------------

sub debug {
   if ($debug) { print STDERR @_ } 
}

my $exit_code = 0;
my @last100lines = ();

LINE:
while (my $line = <>) 
{  
	if (eof) {
		my $mismatches = readpipe("perl $path/mismatch_filter.pl $ARGV");
		if ($?) {
			print "\n########### Mismatches in $ARGV ###\n\n";
			print $mismatches;
			print "########### End of mismatches ###\n\n";
			$exit_code = 1;
		}
		close(ARGV);
		@last100lines = ();
	}
	if ( $line =~ /The last \d+ lines/ ) {
		while ($line = <>) {
			last if ($line =~ /^\#/);
			push @last100lines, $line;
		}
	}
   if ( $line =~ /exited with exit status\s*(\w*)/ and $line !~ /STATUS_OK/ and $line !~ /MISMATCH/ ) {
      $exit_code = 1;
		if ( scalar(@last100lines) ) {
			print "\n\n########### $ARGV ($1): last lines from the error log ###\n\n";
			print @last100lines;
			print "########### End of last lines from the error log for $ARGV ###\n\n\n";
		}
      next;
   }

} 

exit($exit_code);

