#!/bin/bash

# Expects the first argument to be the major version from which we want
# to add tests to the current one.
# It also expects that the current directory is <basedir>,
# and that mysql-test/unstable-tests is the list we are going to add,
# while there is also mysql-test/unstable-tests.$1 list present

if [ -z "$1" ] ; then
  echo "Usage: $0 <major version to add tests from>"
  exit
fi

# Get names of 
awk '{print $1}' mysql-test/unstable-tests | grep -v '^#' | grep -v '^\s*$' | sort > /tmp/unstable-tests.names
awk '{print $1}' mysql-test/unstable-tests.$1 | grep -v '^#' | grep -v '^\s*$' | sort > /tmp/unstable-tests.names.$1

diff /tmp/unstable-tests.names.$1 /tmp/unstable-tests.names | grep '^<' | awk '{print $2" "}'  > /tmp/only_present_in_$1
grep -F -f /tmp/only_present_in_$1 mysql-test/unstable-tests.$1
