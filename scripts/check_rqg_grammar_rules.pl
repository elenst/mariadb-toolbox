#!/usr/bin/perl
#
# Copyright (c) 2022, Elena Stepanova and MariaDB
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1335  USA */

# Find unused and duplicate rules in an RQG grammar

use strict;

my %rules= ();

open(GRAMMAR, $ARGV[0]) || die "Couldn't open the grammar $ARGV[0]: $!\n";
while (<GRAMMAR>) {
  if (/^\s*(\w+)\s*:\s*$/) {
    if (defined $rules{$1}) {
      print "Rule $1 is defined multiple times\n";
    } else {
      $rules{$1}= 0;
    }
  }
}
seek GRAMMAR, 0, 0;
while (<GRAMMAR>) {
  foreach my $r (keys %rules) {
    if (/\W$r\W/ and ! /^\s*$r\s*:\s*$/) {
      $rules{$r}++;
    }
  }
}
close(GRAMMAR);

foreach (keys %rules) {
  if ($rules{$_} == 0) {
    print "Rule $_ is apparently unused\n";
  }
}
