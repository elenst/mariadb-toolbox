#!/usr/bin/perl

use strict;

unless ($ARGV[0]) {
    print "ERROR: Provide the start date for search\n";
    exit 1;
}

my $last_commit= $ARGV[0];
chomp $last_commit;
my $link='https://jira.mariadb.org/issues/?jql=project%20%3D%20MDEV%20AND%20issuetype%20%3D%20Bug%20AND%20resolution%20%3D%20Unresolved%20AND%20component%20%3D%20Tests%20and%20component%20not%20in%20(Galera%2C%20%22Storage%20Engine%20-%20RocksDB%22)%20AND%20created%20%3E%3D%20'.$last_commit;
print "Search query:\n$link\n";
system("wget \"$link\" -O /tmp/unstable_new_mdevs > /dev/null");
my @mdevs;
open(MDEVS,'/tmp/unstable_new_mdevs') || die "Couldn't open /tmp/unstable_new_mdevs\n";
while (<MDEVS>) {
    next unless (/issueKeys\&quot;:\[(.*?)\]/);
    my $mdevs= $1 || '';
    $mdevs =~ s/&quot;//g;
    @mdevs= split /,/, $mdevs;
    last;
}
close(MDEVS);
foreach my $m (@mdevs) {
    print "Searching for $m in mysql-test/unstable-tests... ";
    system("grep $m mysql-test/unstable-tests > /dev/null");
    if ($?) {
        system("wget https://jira.mariadb.org//rest/api/2/issue/$m?fields=versions -O /tmp/unstable_$m.versions -o /dev/null");
        my $ver= `cat /tmp/unstable_$m.versions`;
        my @affected= ($ver =~ /\"name\":\"([^\"]+)/g);
        print "NOT FOUND: https://jira.mariadb.org/browse/$m : @affected\n";
    }
    else {
        print "found.\n";
    }
}
