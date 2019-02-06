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

print "-------------------------------------------------------\n";
print sprintf("| %6s | %10s | %10s | %16s |\n",'','Found','Hit','Total hits');
print "-------------------------------------------------------\n";
print sprintf("| %6s | %10s | %10s | %16s |\n",'line  ',$lcount,$lhits,$ltotal_hits);
print sprintf("| %6s | %10s | %10s | %16s |\n",'branch',$bcount,$bhits,$btotal_hits);
print sprintf("| %6s | %10s | %10s | %16s |\n",'func  ',$fcount,$fhits,$ftotal_hits);
print "-------------------------------------------------------\n";
print "\n";
