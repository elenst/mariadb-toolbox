#!/usr/bin/bash

# Expects:
# - $RQG_HOME (mandatory)
# - $JOB_END (mandatory)
# - $BASEDIR (mandatory)
# - $LOGDIR (mandatory)
# - $GLOBAL_RQG_OPTIONS (optional)
# - $JOB_RQG_OPTIONS (optional)
# - $TEST_RQG_OPTIONS (optional)
# - $TEST_DURATION (optional)

set -x

TEST_DURATION="${TEST_DURATION:-600}"

CURTIME=`date '+%s'`

test_result=0

function soft_exit
{
  return $test_result
}

if [ $((JOB_END - CURTIME)) -gt $((TEST_DURATION + 60)) ] ; then
  cd $RQG_HOME
  perl ./runall-new.pl --basedir=$BASEDIR --vardir=$LOGDIR/vardir $GLOBAL_RQG_OPTIONS $JOB_RQG_OPTIONS $TEST_RQG_OPTIONS > $LOGDIR/trial.log 2>&1
  test_result=$?
  . $SCRIPT_DIR/collect_single_failure_info.sh
else
  echo "Too little time left, skipping the test"
fi

soft_exit

set +x
