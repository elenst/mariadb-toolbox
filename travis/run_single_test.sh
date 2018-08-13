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

TRIAL_COUNT="${TRIAL_COUNT:-0}"
export TRIAL_COUNT=$((TRIAL_COUNT+1))

# Only use the internal counter if the external value doesn't exist or doesn't get updated
if [[ "$TRIAL" -lt "$TRIAL_COUNT" ]] ; then
    export TRIAL=$TRIAL_COUNT
fi

TEST_DURATION="${TEST_DURATION:-600}"

CURTIME=`date '+%s'`

test_result=0

echo ""
echo "============================= Trial $TRIAL ===================================="

if [ $((JOB_END - CURTIME)) -gt $((TEST_DURATION + 60)) ] ; then
  cd $RQG_HOME
  cmd="perl ./runall-new.pl --basedir=$BASEDIR --vardir=$LOGDIR/vardir $GLOBAL_RQG_OPTIONS $JOB_RQG_OPTIONS $TEST_RQG_OPTIONS"
  echo "Running $cmd"
  date
  $cmd > $LOGDIR/trial.log 2>&1
  test_result=$?
  date
  . $SCRIPT_DIR/collect_single_failure_info.sh
else
  echo "Too little time left, skipping the test"
fi

echo "============================= End of trial $TRIAL ============================="

. $SCRIPT_DIR/soft_exit.sh $test_result
