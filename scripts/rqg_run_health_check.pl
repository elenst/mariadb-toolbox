# Count the number of queries with STATUS_OK vs syntax/semantic errors etc.
# In general, the bigger is the share of valid queries, the better
# the test configuration is. There can be exceptions, when a grammar
# is targeted specifically for syntax or semantic errors

use strict;

my @names = ();
foreach (@ARGV) {
  my @expansion = glob($_);
  @names = ( @names, @expansion );
}
@ARGV = @names;

my %all_queries_per_status= ();
my %trial_queries_per_status= ();

my $total_ok= 0;
while (<>) {
  if (eof) {
    print "$ARGV:\n";
    my $total= 0;
    foreach my $s (sort keys %trial_queries_per_status) {
      print sprintf("%12s - %s\n", format_number($trial_queries_per_status{$s}), $s);
      $all_queries_per_status{$s} = ($all_queries_per_status{$s} ? $all_queries_per_status{$s} + $trial_queries_per_status{$s} : $trial_queries_per_status{$s});
      $total+= $trial_queries_per_status{$s};
    }
    $total_ok+= $trial_queries_per_status{STATUS_OK};
    print sprintf("%12s - %s (%.2f%% OK)\n", format_number($total), "Total", ($total ? 100*$trial_queries_per_status{STATUS_OK}/$total : 0));
    %trial_queries_per_status= ();
  }
  next unless /Statuses:.*?(STATUS.*)/;
  my $statuses= $1;
  my %status_counts= ($statuses =~ /(STATUS_.*?):\s+(\d+)/g);
  foreach my $s (keys %status_counts) {
    $trial_queries_per_status{$s} = ($trial_queries_per_status{$s} ? $trial_queries_per_status{$s} + $status_counts{$s} : $status_counts{$s});
  }
}

print "--------------------\nTotal:\n";
my $total= 0;
foreach my $s (sort keys %all_queries_per_status) {
  print sprintf("%12s - %s\n", format_number($all_queries_per_status{$s}), $s);
  $total+= $all_queries_per_status{$s};
}
print sprintf("%12s - %s (%.2f%% OK)\n", format_number($total), "Grand total", ($total ? 100*$total_ok/$total : 0));

sub format_number {
  my $val= shift;
  while ($val =~ s/(.*)(\d)(\d\d\d)/${1}${2},${3}/) {};
  return $val;
}
print "--------------------\n";
