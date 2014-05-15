#!/bin/perl

# The script retrieves the last release tag in the given bzr tree
# and clones the tree using this tag.
# It can be easily done by a chain of shell commands on linux, 
# but we need it to work on Windows, too, 
# so it's better to make it portable from the start.

# The script assumes that releases are tagged as mariadb-<major version>[-<minor version>]

use Getopt::Long;
use strict;

my ($source_tree, $dest_tree);

# Sometimes we want to hardcode a specific revision to be used instead of 
# the release tag. For example, 5.3 has not been released for a long time,
# and a lot was fixed there since the last release, so it makes more sense
# to use a newer revision.
# The map will have a form of <version number> => <revno>,
# which means that if we detected that the current tree has VERSION = <version number>,
# then we'll use <revno> instead of <previous version number>.

my %overridden_revno = ( '5.3.13' => '3622' );

GetOptions(
   'source_tree=s' => \$source_tree,
   'source-tree=s' => \$source_tree,
   'dest_tree=s' => \$dest_tree,
   'dest-tree=s' => \$dest_tree,
);

if (! $source_tree) {
   die "ERROR: Source local bazaar tree must be set\n";
} elsif (! -e $source_tree) {
   die "ERROR: Bazaar tree $source_tree does not exist\n"
} 

if (! $dest_tree) {
   die "ERROR: Destination tree must be set\n";
}

my ($major, $minor, $patch);

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

if ( defined $overridden_revno{"$major.$minor.$patch"} ) {
	my $revno = $overridden_revno{"$major.$minor.$patch"};
	system("bzr branch -r $revno $source_tree $dest_tree");
}
else {
	my $version = "$major.$minor"; 

	open(TAGS,"bzr tags -d $source_tree --sort=time |") || die "ERROR: Could not read bzr tags from $source_tree: $!";
	my $last_release;
	while (<TAGS>) {
		next unless /^(mariadb-$version\S*)/;
		$last_release = $1;
	}
	close(TAGS);

	if (! $last_release) {
		die "ERROR: Could not find a release tag for $version in $source_tree\n";
	}

	system("bzr branch -rtag:$last_release $source_tree $dest_tree");
}
