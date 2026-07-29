# Take the output of lcov and collect summary --
# how many lines/branches/functions were covered, and how many hits they got in total.
# The script presumes that one lcov info per source file is provided(?)
# 
# Helps to check, for example, that during test refactoring tests don't lose coverage

use strict;

my ($lcount, $bcount, $fcount, $lhits, $bhits, $fhits, $ltotal_hits, $btotal_hits, $ftotal_hits);

# We'll ignore lcov's summaries and get our own, because we want total number of hits

my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

my %lines_per_file= ();
#my %branches_per_file= ();
#my %func_per_file= ();
my %lcount_per_file= ();
my %ltotal_hits_per_file= ();

while (<>) {

    if (eof) {
      $lines_per_file{$ARGV}= $lhits;
      $lcount_per_file{$ARGV}= $lcount;
      $ltotal_hits_per_file{$ARGV}= $ltotal_hits;
      ($lhits, $lcount, $ltotal_hits)= (0,0,0);
#      $branches_per_file{$ARGV}= $bhits;
#      $funcs_per_file{$ARGV}= $fhits;
      close (ARGV);
    }
    if (/^DA:\d+,([-\d]+)/) {
        # line coverage
        my $cnt = ($1 eq '-' ? 0 : $1);
        $lcount++;
        $lhits++ if ($cnt > 0);
        $ltotal_hits += $cnt;
    }
#    elsif (/^BRDA:\d+,\d+,\d+,([-\d]+)/) {
#        # branch coverage
#        my $cnt = ($1 eq '-' ? 0 : $1);
#        $bcount++;
#        $bhits++ if ($cnt > 0);
#        $btotal_hits += $cnt;
#    }
#    elsif (/^FNDA:([-\d]+)/) {
#        # function coverage
#        my $cnt = ($1 eq '-' ? 0 : $1);
#        $fcount++;
#        $fhits++ if ($cnt > 0);
#        $ftotal_hits += $cnt;
#    }
}

print "-----------------------------------------------------------------------------------------------------------------------\n";
print sprintf("| %70s | %10s | %10s | %16s |\n",'','Found','Hit','Total hits');
print "-----------------------------------------------------------------------------------------------------------------------\n";
foreach my $f (sort keys %lines_per_file) {
  my $tname= $f;
  $tname=~ s/.*lcov.info.//;
  print sprintf("| %70s | %10s | %10s | %16s |\n","$tname ",$lcount_per_file{$f},$lines_per_file{$f},$ltotal_hits_per_file{$f});
}
#print sprintf("| %6s | %10s | %10s | %16s |\n",'branch',$bcount,$bhits,$btotal_hits);
#print sprintf("| %6s | %10s | %10s | %16s |\n",'func  ',$fcount,$fhits,$ftotal_hits);
print "-----------------------------------------------------------------------------------------------------------------------\n";
print "\n";
