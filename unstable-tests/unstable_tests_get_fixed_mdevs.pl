#!/usr/bin/perl

# Expects that the current dir is the <basedir>, and mysql-test/unstable-tests is present

open(UNSTABLE,'mysql-test/unstable-tests') || die "Couldn't open mysql-test/unstable-tests for reading";
system("rm /tmp/unstable_MDEV-*");
my %mdev_resolution= ();
my %mdev_fixversion= ();
my %checked_mdevs= ();
while (<UNSTABLE>) {
    if (/(MDEV-\d+)/) {
        my $mdev= $1;
        next if $checked_mdevs{$mdev};
        $checked_mdevs{$mdev}= 1;
        my $resolution;
        if (not exists $mdev_resolution{$mdev}) {
            system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=resolution -O /tmp/unstable_$mdev.resolution -o /dev/null");
            my $resolution= `cat /tmp/unstable_$mdev.resolution`;
            if ($resolution=~ s/.*\"name\":\"([^\"]+)\".*/$1/) {
                system("wget https://jira.mariadb.org//rest/api/2/issue/$mdev?fields=fixVersions -O /tmp/unstable_$mdev.fixVersions -o /dev/null");
                my $fixver= `cat /tmp/unstable_$mdev.fixVersions`;
                @fixvers= ($fixver =~ /\"name\":\"([^\"]+)/g);
                # Not 'Unresoloved'
                $mdev_fixversion{$mdev}= "@fixvers";
                $mdev_resolution{$mdev}= $resolution;
            }
        }
        if ($mdev_resolution{$mdev}) {
            print "$mdev : $mdev_resolution{$mdev} : $mdev_fixversion{$mdev}\n";
        }
    }
}
close(UNSTABLE);
