#!/usr/bin/perl

use Getopt::Long;
use strict;

my @branches;
my @builds;
my ($bin_home, $source_home, $remote_source);

GetOptions (
  "bin-home=s" => \$bin_home,
  "source-home=s" => \$source_home,
  "remote-source=s" => \$remote_source,
  "branch=s@" => \@branches,
  "build=s@"  => \@builds,
);

unless (scalar @builds) {
    @builds= ('deb', 'rel');
}

say("Branches to build: @branches");
say("Build types: @builds");

my %builds=();
map { $builds{$_}= 1 } @builds;

foreach my $b (@branches)
{
    my $srcdir= "$source_home/$b";
    my ($revno, $remote_revno, $bindir);
    if (-e $srcdir) {
        system("cd $srcdir; git log -1 --abbrev=8 --pretty=\"%h\" > revno; git ls-remote origin $b | cut -c 1-8 > remote_revno");
        $revno=`cat $srcdir/revno`;
        chomp $revno;
        my $remote_revno=`cat $srcdir/remote_revno`;
        chomp $remote_revno;
        if ($revno ne $remote_revno) {
            system("cd $source_home; rm -rf $b");
        }
    }

    unless (-e $srcdir) {
        if (-e "$remote_source/$b") {
            system("cd $source_home; git clone $remote_source/$b $b");
        } else {
            system("cd $source_home; git clone $remote_source --branch $b $b");
        }
    }

    # Release build
    if ($builds{'rel'}) {
        $bindir= "$bin_home/${b}-${revno}-rel";
        if (-e $bindir) {
            say("Release build for $b $revno already exists");
        } else {
            build($srcdir, $bindir, "$bin_home/${b}-rel", "-DCMAKE_BUILD_TYPE=RelWithDebInfo");
        }
    }

    # ASAN build
    if ($builds{'asan'}) {
        $bindir= "$bin_home/${b}-${revno}-asan";
        if (-e $bindir) {
            say("ASAN build for $b $revno already exists");
        } else {
            build($srcdir, $bindir, "$bin_home/${b}-asan", "-DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF");
        }
    }
    
    # Debug build
    if ($builds{'deb'}) {
        $bindir= "$bin_home/${b}-${revno}-deb";
        if (-e $bindir) {
            say("Debug build for $b $revno already exists");
        } else {
            build($srcdir, $bindir, "$bin_home/${b}-deb", "-DCMAKE_BUILD_TYPE=Debug");
        }
    }

    # GCOV build, has to be in-source
    if ($builds{'gcov'}) {
        $bindir= "$bin_home/${b}-${revno}-gcov";
        if (-e $bindir) {
            say("GCOV build for $b $revno already exists");
        } else {
            system("cd $bin_home; git clone $srcdir $bindir");
            build($bindir, undef, "$bin_home/${b}-gcov", "-DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=YES");
        }
    }
}

sub say {
    my $ts= sprintf("%04d-%02d-%02d %02d:%02d:%02d",(localtime())[5]+1900,(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0]);
    my @lines= ();
    map { push @lines, split /\n/, $_ } @_;
    foreach my $l (@lines) {
        print $ts, ' ', $l, "\n";
    }
}

sub build {
    my $srcdir= shift;
    my $installdir= shift;
    my $symlink= shift;
    my @cmake_args= @_;
    if ($installdir) {
        # Out-of-source build
        system("rm -rf /dev/shm/tmp_build && mkdir /dev/shm/tmp_build && cd /dev/shm/tmp_build && cmake $srcdir @cmake_args -DCMAKE_INSTALL_PREFIX=$installdir && make -j16 && rm -rf $installdir && make install");
        # Update symlink
        if ($?==0) {
            system("rm $symlink; ln -s $installdir $symlink");
        }
    } else {
        # In-source build (e.g. for GCOV)
        system("cd $srcdir && cmake . -DMAX_INDEXES=128 @cmake_args && make -j12");
        # Update symlink
        if ($?==0) {
            system("rm $symlink; ln -s $srcdir $symlink");
        }
    }
}
