#!/usr/bin/perl
use strict;
use warnings;

# Check if the filename is provided as an argument
if (@ARGV != 1) {
    die "Usage: $0 input_file\n";
}

my $input_file= shift;

open my $in, '<', $input_file or die "Cannot open '$input_file': $!\n";

while (my $line = <$in>) {
    print lc($line);  # Convert the line to lowercase and write to the output file
}
