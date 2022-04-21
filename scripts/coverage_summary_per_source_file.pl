# Take the output of lcov and collect summary --
# how many lines/branches/functions were covered, and how many hits they got in total.
# The script presumes that one lcov info is given and extracts per-file information from it
#
# No branch/function counts, only line

use strict;

# Hash of arrays
# hash key is the file path/name
# hash value is an array of three elements:
# - instrumented lines,
# - hit lines,
# - total number of hits

my %stats_per_file= ();
my $sourcedir; # To be defined based on lcov.info contents
my $max_name_length= 0;
my $fname;
my $skip_patterns= qr/\/unittest|mysql-test\//;

my ($instrumented, $hit, $total_hits)= (0,0,0);
while (<>) {
    # Line stats
    if ($fname and /^DA:\d+,([-\d]+)/) {
        # line coverage
        my $cnt= $1;
        # Don't remember why I have this logic, maybe gcov sets '-' somewhere
        if ($cnt eq '-' or $cnt < 0) { $cnt= 0 };
        $instrumented++;
        $hit++ if $cnt > 0;
        $total_hits+= $cnt;
    }
    elsif (/^SF:(.*)$/) {
        if ($fname) {
            $stats_per_file{$fname}= [$instrumented, $hit, $total_hits];
            ($instrumented, $hit, $total_hits)= (0,0,0);
        }
        $fname= $1;
        chomp $fname;
        $max_name_length= length($fname) if length($fname) > $max_name_length;
        if ($fname =~ /$skip_patterns/) {
            $fname= undef;
        } elsif ($fname =~ /^(.*\/)sql\/main\.cc/) {
            # We'll use it later to trim file names
            $sourcedir= $1;
        }
    }
}

$max_name_length= $max_name_length - length($sourcedir);
my ($total_instrumented,$total_hit,$grand_total_hits)= (0,0,0);
my $separator= "\n";
for (1 .. 2 + $max_name_length + 3 + 10 + 3 + 10 + 3 + 7 + 3 + 16 + 2) { $separator = "-${separator}" };
print $separator;
print sprintf("| %${max_name_length}s | %10s | %10s | %7s | %16s |\n",'','Instr','Hit','Pct','Total hits');
print $separator;
foreach my $f (sort keys %stats_per_file) {
  $fname= $f;
  $fname=~ s/$sourcedir//;
  ($instrumented, $hit, $total_hits) = @{$stats_per_file{$f}};
  $total_instrumented+= $instrumented;
  $total_hit+= $hit;
  $grand_total_hits+= $total_hits;
  print sprintf("| %${max_name_length}s | %10s | %10s | %7s | %16s |\n","$fname ",$instrumented,$hit,sprintf("%.2f%",100*$hit/$instrumented),$total_hits);
}
print $separator;
print sprintf("| %${max_name_length}s | %10s | %10s | %7s | %16s |\n","Total ",$total_instrumented,$total_hit,sprintf("%.2f%",100*$total_hit/$total_instrumented),$grand_total_hits);
print $separator;
print "\n";
