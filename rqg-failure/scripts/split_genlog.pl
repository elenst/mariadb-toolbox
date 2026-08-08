#!/usr/bin/perl
# Split the general log of RQG trial 767-46 into one replayable SQL file per
# connection, for a given time window of the last server incarnation.
#
#   split_genlog.pl <general.log> <outdir> <from HH:MM:SS> <to HH:MM:SS>
#
# The general log format is
#   YYMMDD HH:MM:SS<TAB><id> Command<TAB>Argument
# with the timestamp omitted while the second does not change and the id
# omitted on continuation lines of a multi-line statement.
use strict; use warnings;

my ($log, $outdir, $from, $to) = @ARGV;
die "usage: $0 <general.log> <outdir> <from> <to>\n" unless $to;
mkdir $outdir unless -d $outdir;

open(my $fh, '<', $log) or die "$log: $!";

my ($ts, $id, $cmd) = ('', 0, '');
my %out;                       # id => filehandle
my %n;                         # id => statement count
my $started = 0;               # seen the last "started with:" header?
my $buf;                       # current statement being accumulated
my ($buf_id, $buf_ts);

# First pass: find the offset of the last server incarnation.
my $last_hdr = 0;
while (<$fh>) { $last_hdr = $. if /started with:$/; }
seek($fh, 0, 0); $. = 0;

sub flush_stmt {
  return unless defined $buf;
  if ($buf_ts ge $from && $buf_ts le $to && $buf =~ /\S/) {
    unless ($out{$buf_id}) {
      open(my $o, '>', "$outdir/c$buf_id.sql") or die $!;
      $out{$buf_id} = $o;
    }
    my $s = $buf;
    $s =~ s/\s+\z//;
    $s =~ s/;\z//;
    print {$out{$buf_id}} "$s;\n";
    $n{$buf_id}++;
  }
  undef $buf;
}

while (my $line = <$fh>) {
  next if $. <= $last_hdr + 2;                 # skip header lines
  chomp $line;
  my $rest;
  if ($line =~ /^(\d{6}) (\d\d:\d\d:\d\d)\t(.*)$/) { $ts = $2; $rest = $3; }
  elsif ($line =~ /^\t\t(.*)$/)                    { $rest = $1; }
  else { $buf .= "\n$line" if defined $buf; next } # continuation of a statement

  if ($rest =~ /^\s*(\d+) (Query|Connect|Quit|Init DB|Prepare|Execute|Close stmt|Reset stmt|Statistics|Refresh|Shutdown|Field List|Ping|Change user)\t?(.*)$/) {
    flush_stmt();
    ($id, $cmd, my $arg) = ($1, $2, $3);
    if ($cmd eq 'Query') { ($buf, $buf_id, $buf_ts) = ($arg, $id, $ts); }
  }
  else {
    $buf .= "\n$rest" if defined $buf;           # continuation
  }
}
flush_stmt();
close $_ for values %out;
printf "%-8s %s\n", "conn", "statements";
printf "c%-7s %d\n", $_, $n{$_} for sort { $a <=> $b } keys %n;
