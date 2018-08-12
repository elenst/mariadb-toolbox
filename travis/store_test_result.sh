#!/usr/bin/bash

# Expects:
# - BASEDIR
# - TRAVIS_TEST_RESULT (travis internal)

if [ ! -e $BASEDIR/test_result ] ; then
  echo $TRAVIS_TEST_RESULT > $BASEDIR/test_result
fi
