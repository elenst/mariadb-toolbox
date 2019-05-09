#!/usr/bin/perl

# Simple script to summarize statistics printed by RQG in lines like
# # 2019-05-09T23:47:52 [15799] Statuses: STATUS_OK: 2127 queries, STATUS_SYNTAX_ERROR: 10 queries, STATUS_SEMANTIC_ERROR: 1069 queries, STATUS_TRANSACTION_ERROR: 9 queries

my %status_count= ();

while (<>) {
    next unless /Statuses: (.*)/;
    chomp $1;
    my @stats= split /,/, $1;
    foreach my $s (@stats) {
        next unless $s =~ /STATUS_(.*): (\d+) queries/;
        $status_count{$1}= (exists $status_count{$1} ? $status_count{$1} + $2 : $2);
    }
}

foreach my $s (sort keys %status_count) {
    print sprintf "%20s: %d\n", $s, $status_count{$s};
}
