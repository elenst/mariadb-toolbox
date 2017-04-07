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
my @lastLines = ();
my %failedThreads = ();
# Last line which a perl thread printed
my %threadLines = ();
my $seed;
my $start_cmd;

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
        @lastLines = ();
        %failedThreads = ();
        %threadLines = ();
		$seed= undef;
		$start_cmd= undef;
    }

    if ( $line =~ /Starting:\s+(.*runall\.pl.*)/ ) {
		$start_cmd= $1;
		chomp $start_cmd;
	}
	elsif ( $line =~ /Converting --seed=time to --(seed=\d+)/ ) {
		$seed= $1;
	}
	elsif ( $line =~ /Final command line:/ ) {
		$line= <>;
		if ( $line =~ /(perl\s+.*runall-new.pl.*)/ ) {
			$start_cmd= $1;
			chomp $start_cmd;
		}
	}

    if ( $line =~ /The last \d+ lines from .*?(?:current(\d))?/ ) {
        my $server = '?';
        if ( $line =~ /current(\d)_\d/ ) {
            $server = $1;
        }
        push @lastLines, "### Last interesting lines from the error log of server $server ###\n\n";
        while ($line = <>) {
            last if ($line =~ /^\#/);
            next if ($line =~ / \[Note\] / or $line =~ /InnoDB: DEBUG: /);
            push @lastLines, $line;
        }
    }
    if ( $line =~ /exited with exit status\s*(\w*)/ and $line !~ /STATUS_OK/ and $line !~ /MISMATCH/ ) {
        $exit_code = 1;
        print "\n\n########### $ARGV ($1): ###########\n\n";
		if ($seed) {
			print "$seed\n";
		}
        if ($start_cmd) {
			print "Command line:\n$start_cmd\n\n";
		}
        if ( scalar(@lastLines) ) {
            print ;
            print @lastLines;
            print "########### End of last lines from the error log for $ARGV ###\n\n";
        }
        if ( scalar(keys %failedThreads) ) {
            print "### Last lines for from failed threads ###\n\n";
            foreach my $t (keys %failedThreads) {
                print "Thread $t ($failedThreads{$t}):\n\t@{$threadLines{$t}}\n";
            }
        }
		next;
    }
    # For now lets print last lines only for DATABASE_CORRUPTION
    elsif ( $line =~ /\[([-\d]+)\]\s+GenTest:\s+child is being stopped with status (STATUS_DATABASE_CORRUPTION)/ ) {
        $failedThreads{$1} = $2 if $2 ne 'STATUS_OK';
    }
    # Store few last lines for each thread
    elsif ( $line =~ /\#\s\d{4}-\d+-\d+T\d+:\d+:\d+\s\[([-\d]+)\]/ ) {
        @{$threadLines{$1}} = () if not exists $threadLines{$1};
        shift @{$threadLines{$1}} if (scalar @{$threadLines{$1}} >=5);
        push @{$threadLines{$1}}, $line;
    }
}

exit($exit_code);

