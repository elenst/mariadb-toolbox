#!/usr/bin/perl

open(UNSTABLE,'mysql-test/unstable-tests') || die "Couldn't open mysql-test/unstable-tests\n";
print "CREATE OR REPLACE TEMPORARY TABLE buildbot_analytics.known_bugs (test_name VARCHAR(256));\n";
print "REPLACE INTO buildbot_analytics.known_bugs VALUES";
my $values=" ";
while (<UNSTABLE>) {
    next unless /^\s*([-\w\.\/]+).*MDEV-/;
    $values.= "('$1'),";
}
chop $values;
print "$values;\n";

    
