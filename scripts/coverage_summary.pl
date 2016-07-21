# Take the output of lcov and collect summary --
# how many lines/branches/functions were covered, and how many hits they got in total.
# 
# Helps to check, for example, that during test refactoring tests don't lose coverage

use strict;

my ($lcount, $bcount, $fcount, $lhits, $bhits, $fhits, $ltotal_hits, $btotal_hits, $ftotal_hits);

# We'll ignore lcov's summaries and get our own, because we want total number of hits

while (<>) {
    if (/^DA:\d+,([-\d]+)/) {
        # line coverage
        my $cnt = ($1 eq '-' ? 0 : $1);
        $lcount++;
        $lhits++ if ($cnt > 0);
        $ltotal_hits += $cnt;
    }
    elsif (/^BRDA:\d+,\d+,\d+,([-\d]+)/) {
        # branch coverage
        my $cnt = ($1 eq '-' ? 0 : $1);
        $bcount++;
        $bhits++ if ($cnt > 0);
        $btotal_hits += $cnt;
    }
    elsif (/^FNDA:([-\d]+)/) {
        # function coverage
        my $cnt = ($1 eq '-' ? 0 : $1);
        $fcount++;
        $fhits++ if ($cnt > 0);
        $ftotal_hits += $cnt;
    }
}

print "\n\tFound\tHit\tNumber of hits\n";
print "line\t$lcount\t$lhits\t$ltotal_hits\n";
print "branch\t$bcount\t$bhits\t$btotal_hits\n";
print "func\t$fcount\t$fhits\t$ftotal_hits\n";
print "\n";
