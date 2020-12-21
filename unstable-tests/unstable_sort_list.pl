#!/usr/bin/perl

use strict;

my %tests;
my @comments;

my $version= `cat VERSION`;
my @ver= $version =~ /=(\d+)/gs;
$version= join '.', @ver;

# max length per suite
my %max_lengths;

# hash of arrays
my %suite_tests;

my ($test, $suite, $text);

while (<>) {
  if (/^\s*\#/) {
    push @comments, $_ unless /^\s*\#\-+\s*$/;
  }
  elsif (/^\s*(([^\.]+)\.\S+)[\s:]+(.*)/) {
    ($test, $suite, $text)= ($1, $2, $3);
    if (exists $tests{$test}) {
        push @{$tests{$test}}, $text;
    } else {
        @{$tests{$test}} = ( $text );
        if (exists $suite_tests{$suite}) {
            push @{$suite_tests{$suite}}, $test;
        } else {
            @{$suite_tests{$suite}} = ( $test );
        }
    }
    if (length($test) > $max_lengths{$suite}-1) {
      $max_lengths{$suite}= length($test)+1;
    }
  }
}

foreach my $t (keys %tests) {
    my $text= '';
    my $modified= '';
    my $aux_modified= '';
    my $old_modified= '';
    my $old_aux_modified= '';
    foreach my $l (@{$tests{$t}}) {
        my @reasons= split /;/, $l;
        my %reasons= ();
        foreach my $r (@reasons) {
            $r =~ s/^\s*(.*)?\s*$/$1/;
            # Avoid duplicates
            next if exists $reasons{$r};
            $reasons{$r}= 1;
            # The test itself modified in the last version, that's the highest priority modification
            if ($r =~ /^(?:modified|added|deleted) in $version/i) {
                $modified= $r;
            # Include or configuration was modified in the last version, that's 2nd tier
            } elsif ($r =~ /.+(?:modified|added|deleted) in $version/) {
                $aux_modified= $r;
            # The test was modified in an older version, it's the 3rd tier
            } elsif ($r =~ /^(?:modified|added|deleted) in /i) {
                $old_modified= $r;
            # Include or configuration was modified in an older version, that's 4th tier
            } elsif ($r =~ /.+(?:modified|added|deleted) in /) {
                $old_aux_modified= $r;
            # Something else, it should probably stay
            } else {
                $text= ($text ? "$text; $r" : $r);
            }
        }
    }
    if ($modified) {
        $text= ($text ? "$text; ".lc($modified) : $modified);
    } elsif ($aux_modified) {
        $text= ($text ? "$text; ".lc($aux_modified) : $aux_modified);
    } elsif ($old_modified) {
        $text= ($text ? "$text; ".lc($old_modified) : $old_modified);
    } elsif ($old_aux_modified) {
        $text= ($text ? "$text; ".lc($old_aux_modified) : $old_aux_modified);
    }
    $tests{$t}= $text;
}

foreach (@comments) {
  print;
}
print "\n";

#my $current_suite= '';

foreach (sort @{$suite_tests{main}}) {
    print sprintf "%-$max_lengths{main}s: $tests{$_}\n", $_;
}
delete $suite_tests{main};

foreach my $s (sort keys %suite_tests) {
    print "\n#-----------------------------------------------------------------------\n\n";
    my @tests= @{$suite_tests{$s}};
    foreach my $t (sort @tests) {
        print sprintf "%-$max_lengths{$s}s: $tests{$t}\n", $t;
    }
}
