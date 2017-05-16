#!/bin/perl

# The script attempts to clone the given bzr/git tree by the last release tag.
# It can be easily done by a chain of shell commands on linux,
# but we need it to work on Windows, too,
# so it's better to make it portable from the start.

# The script assumes that releases are tagged as mariadb-<major version>-<minor version>-<patch>[<maybe something else>]

use Getopt::Long;
use strict;

use constant REPO_BZR => 1;
use constant REPO_GIT => 2;

my ($source_tree, $dest_tree, $repo_type);
my $debug = 0;

my $cd= (osWindows() ? "cd /d" : "cd");

# Sometimes we want to hardcode a specific revision to be used instead of
# the release tag. For example, 5.3 has not been released for a long time,
# and a lot was fixed there since the last release, so it makes more sense
# to use a newer revision.
# The map will have a form of <version number> => <revision>,
# which means that if we detected that the current tree has VERSION = <version number>,
# then we'll use <revno> instead of <previous version number>.

# 10.0 : until 10.0.31 is released
# TODO:
# 10.1: wait till b0395d8701ec49f49ad23f9917a3b2369bb49e7a is merged into 10.1, then set
# the merge until 10.1.23 is released.
# Same for 10.2 until 10.2.6 is released
my %overridden_rev = ( '5.3' => '3622', '10.0' => '8d75a7533ee80efa5275a058dfadf8947e5857a6', '10.2' => 'c91ecf9e9bebf3cf2dafbd3193de4df94be09870' );

GetOptions(
   'source_tree=s' => \$source_tree,
   'source-tree=s' => \$source_tree,
   'dest_tree=s' => \$dest_tree,
   'dest-tree=s' => \$dest_tree,
    'debug!' => \$debug
);

if (! $source_tree) {
   die "ERROR: Source local bazaar/git tree must be set\n";
} elsif (! -e $source_tree) {
   die "ERROR: Source tree $source_tree does not exist\n"
} elsif (! -e "$source_tree/.bzr" and ! -e "$source_tree/.git") {
    die "ERROR: Source tree does not look like either bzr or git tree\n";
}

if (! $dest_tree) {
   die "ERROR: Destination tree must be set\n";
}

$repo_type = (-e "$source_tree/.git" ? REPO_GIT : REPO_BZR);


my ($major, $minor, $patch, $version, $revision);

if ( -e "$source_tree/VERSION" ) {
    open(VERSION,"$source_tree/VERSION") || die "ERROR: Could not open file $source_tree/VERSION: $!";
    while (<VERSION>) {
        if (/VERSION_MAJOR=(\d+)/) { $major = $1 }
        elsif (/VERSION_MINOR=(\d+)/) { $minor = $1 }
        elsif (/VERSION_PATCH=(\d+)/) { $patch = $1 }
    }
    close(VERSION);
}
elsif ( -e "$source_tree/configure.in" ) {
    open(VERSION,"$source_tree/configure.in") || die "ERROR: Could not open file $source_tree/configure.in: $!";
    while (<VERSION>) {
        if (/AC_INIT.*(\d+)\.(\d+)\.(\d+)-MariaDB/) {
            $major = $1;
            $minor = $2;
            $patch = $3;
            last;
        }
    }
    close(VERSION);
}

if (! defined $major or ! defined $minor) {
   die "ERROR: Could not retrieve server version\n";
}

$version = "$major.$minor";

if ( defined $overridden_rev{$version} ) {
    print "For version $version the previous release tag is overridden to $overridden_rev{$version}\n";
    $revision = $overridden_rev{$version};
#    system("bzr branch -r $revno $source_tree $dest_tree");
#} elsif ( $patch == 0 ) {
#    die "ERROR: it's the first minor release in the line, and there is no overridden revision\n";
} else {
#    my $prev_version = "$major.$minor.".($patch-1);

    $revision = find_tag($source_tree, $version, $repo_type);

    if (! $revision) {
        die "ERROR: Could not find a release tag for $version in $source_tree\n";
    }

}

clone_tree($source_tree, $dest_tree, $revision, $repo_type);

sub clone_tree {
    my ( $src, $dest, $rev, $repo ) = @_;

    my $cmd = ( $repo == REPO_BZR
        ? "bzr branch -r $rev $src $dest"
        : "$cd $src/.. && git clone $src $dest && $cd $dest && pwd && git branch && git checkout $rev"
    );
    print("To clone the tree, running $cmd\n");
    system("$cmd");
}


sub find_tag {
    my ( $src, $ver, $repo ) = @_;
    my $cmd = ( $repo == REPO_BZR
        ? "bzr tags -d $src --sort=time"
        : "$cd $src && git for-each-ref --count=1 --sort=-authordate --format=%(refname) refs/tags/mariadb-$ver.*"
    );
    debug("To find the tag, running $cmd\n");
    open(TAGS, "$cmd |") || die "ERROR: Could not read repo tags from $src: $!\n";
    my $tag;
    while (<TAGS>) {
        debug("Checking tag $_\n");
        next unless /^(?:refs\/tags\/)?(mariadb-$version\.\S+)/;
        $tag = $1;
    }
    close(TAGS);
    return $tag;
}

sub debug {
    print @_ if $debug;
}

sub osWindows {
    if (
		($^O eq 'MSWin32') ||
		($^O eq 'MSWin64')
    ) {
		return 1;
    } else {
		return 0;
    }
}
