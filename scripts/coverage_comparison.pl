# Compare two outputs of lcov to see gains and losses in coverage between different test runs
# We don't care about the number of hits here, only whether a line/branch/function was hit at all or not

use strict;

if ((scalar @ARGV) != 2) {
    print "ERROR: the script takes 2 lcov info files\n";
    exit(1);
}

my ($f1, $f2) = @ARGV;
my (%lines_hit1, %branches_hit1, %funcs_hit1, %lines_hit2, %branches_hit2, %funcs_hit2);
my (%lines_missed1, %branches_missed1, %funcs_missed1, %lines_missed2, %branches_missed2, %funcs_missed2);

my $current_file;

open(LCOV,$f1) || die "Could not open file $f1 for reading: $!\n";
while (<LCOV>) {
    if (/^SF:(.*)/) {
        chomp;
        $current_file = $1;
    }
    elsif (/^DA:(\d+),([-\d]+)/) {
        my $cnt = ($2 eq '-' ? 0 : $2);
        my $ln = $current_file.':'.$1;
        if ($cnt > 0) {
            $lines_hit1{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $lines_missed1{$ln};
        } elsif (not $lines_hit1{$ln}) {
            $lines_missed1{$ln} = 1;
#        print "HERE:1: line $ln cnt $cnt\n";
        }
    }
    elsif (/^BRDA:(\d+,\d+,\d+),([-\d]+)/) {
        my $cnt = ($2 eq '-' ? 0 : $2);
        my $ln = $current_file.':'.$1;
        if ($cnt > 0) {
            $branches_hit1{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $branches_missed1{$ln};
        } elsif (not $branches_hit1{$ln}) {
            $branches_missed1{$ln} = 1;
        }
    }
    elsif (/^FNDA:([-\d]+),(.*)/) {
        my $cnt = ($1 eq '-' ? 0 : $1);
        my $ln = $current_file.':'.$2;
        chomp $ln;
        if ($cnt > 0) {
            $funcs_hit1{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $funcs_missed1{$ln};
        } elsif (not $funcs_hit1{$ln}) {
            $funcs_missed1{$ln} = 1;
        }
    }
}
close (LCOV);

open(LCOV,$f2) || die "Could not open file $f2 for reading: $!\n";
while (<LCOV>) {
    if (/^SF:(.*)/) {
        chomp;
        $current_file = $1;
    }
    elsif (/^DA:(\d+),([-\d]+)/) {
        my $cnt = ($2 eq '-' ? 0 : $2);
        my $ln = $current_file.':'.$1;
        if ($cnt > 0) {
            $lines_hit2{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $lines_missed2{$ln};
        } elsif (not $lines_hit2{$ln}) {
            $lines_missed2{$ln} = 1;
#            print "HERE:2: line $ln cnt $cnt\n";
        }
    }
    elsif (/^BRDA:(\d+,\d+,\d+),([-\d]+)/) {
        my $cnt = ($2 eq '-' ? 0 : $2);
        my $ln = $current_file.':'.$1;
        if ($cnt > 0) {
            $branches_hit2{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $branches_missed2{$ln};
        } elsif (not $branches_hit2{$ln}) {
            $branches_missed2{$ln} = 1;
        }
    }
    elsif (/^FNDA:([-\d]+),(.*)/) {
        my $cnt = ($1 eq '-' ? 0 : $1);
        my $ln = $current_file.':'.$2;
        chomp $ln;
        if ($cnt > 0) {
            $funcs_hit2{$ln} = 1;
            # Just in case the file appears in lcov output more than once, happens to headers for example
            delete $funcs_missed2{$ln};
        } elsif (not $funcs_hit2{$ln}) {
            $funcs_missed2{$ln} = 1;
        }
    }
}
close (LCOV);

#print "-----------------------------------------------------\n";
#print "---Lines covered by the second run, but not first:---\n";
#print "-----------------------------------------------------\n";
#foreach my $l (sort keys %lines_hit2) {
#    print "$l\n" if ($lines_missed1{$l});
#}

#print "-----------------------------------------------------\n";
#print "---Branches covered by the second run, but not first:\n";
#print "-----------------------------------------------------\n";
#foreach my $b (sort keys %branches_hit2) {
#    print "$b\n" if ($branches_missed1{$b});
#}

#print "------------------------------------------------------\n";
#print "---Functions covered by the second run, but not first:\n";
#print "------------------------------------------------------\n";
#foreach my $f (sort keys %funcs_hit2) {
#    print "$f\n" if ($funcs_missed1{$f});
#}

print "-----------------------------------------------------\n";
print "---Lines covered by the first run, but not second:---\n";
print "-----------------------------------------------------\n";
foreach my $l (sort keys %lines_hit1) {
    print "$l\n" if ($lines_missed2{$l});
}

#print "-----------------------------------------------------\n";
#print "---Branches covered by the first run, but not second:\n";
#print "-----------------------------------------------------\n";
#foreach my $b (sort keys %branches_hit1) {
#    print "$b\n" if ($branches_missed2{$b});
#}
#
#print "------------------------------------------------------\n";
#print "---Functions covered by the first run, but not second:\n";
#print "------------------------------------------------------\n";
#foreach my $f (sort keys %funcs_hit1) {
#    print "$f\n" if ($funcs_missed2{$f});
#}

