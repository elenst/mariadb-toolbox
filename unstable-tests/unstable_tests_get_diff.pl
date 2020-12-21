#!/bin/perl

unless (-e 'mysql-test/unstable-tests') {
    print "ERROR: Wrong starting point, go to <basedir>\n";
    exit 1;
}

my $revno=($ARGV[0] ? $ARGV[0] : `git log -1 --abbrev=8 --pretty="%h" mysql-test/unstable-tests`);
chomp $revno;

my $version= `cat VERSION`;
my @ver= $version =~ /=(\d+)/gs;
$version= join '.', @ver;

my $original= "/data/tmp/diff.$version";
my $filtered= "/data/tmp/diff.${version}.filtered";

system("git diff $revno mysql-test/ storage/*/mysql-test plugin/*/mysql-test > $original");
open(DIFF,$original) || die "Couldn't open $original: $!\n";
open(DIFF2,">$filtered") || die "Couldn't open $filtered for writing: $!\n";

my $skip_diff= 0;
my $path;
while (<DIFF>)
{
    unless (/diff --git a\/(\S+)/) {
        print DIFF2 $_ unless $skip_diff;
        next;
    }
    $path= $1;

    if ($path =~ /\.(?:result|rdiff|unstable-tests|valgrind\.supp)$/ or $path =~ /^mysql-test\/suite\/galera/ or $path =~ /^storage\/rocksdb/ or $path=~ /\/storage_engine\//) {
        $skip_diff= 1;
        next;
    } else {
        $skip_diff= 0;
        print DIFF2 $_;
    }

    my $change=<DIFF>;
    print DIFF2 $change;
}

close(DIFF);
close(DIFF2);

print "Resulting file: $filtered\n";

