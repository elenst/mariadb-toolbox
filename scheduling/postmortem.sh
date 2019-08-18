#!/bin/bash

# Expects in environment:
# SERVER_BRANCH
# TEST_ALIAS
# TEST_ID
# LOGDIR
# TEST_ID

PREFIX=$TEST_ID"_"

resline=`grep 'runall.* will exit with exit status' $LOGDIR/${PREFIX}trial.log || grep 'GenTest exited with exit status' $LOGDIR/${PREFIX}trial.log || grep 'GenTest will exit with exit status' $LOGDIR/${PREFIX}trial.log`;

TEST_RESULT=`echo $resline | sed -e 's/.*exit status STATUS_\([A-Z_]*\).*/\\1/g'`

LOCAL_CI=`hostname`

SIGNATURES="--signatures=$RQG_HOME/data/bug_signatures"
if [[ $SERVER_BRANCH =~ enterprise ]] ; then
    SIGNATURES="$SIGNATURES --signatures=$RQG_HOME/data/bug_signatures.es"
fi

SERVER_BRANCH=$SERVER_BRANCH TEST_ALIAS=$TEST_ALIAS TEST_RESULT=$TEST_RESULT TEST_ID=$TEST_ID LOCAL_CI=$LOCAL_CI perl $RQG_HOME/util/check_for_known_bugs.pl $SIGNATURES `find $LOGDIR/${PREFIX}vardir* -name mysql*.err*` `find $LOGDIR/${PREFIX}vardir* -name mbackup*.log` --last=$LOGDIR/${PREFIX}trial.log

echo SERVER_BRANCH=$SERVER_BRANCH TEST_ALIAS=$TEST_ALIAS TEST_RESULT=$TEST_RESULT TEST_ID=$TEST_ID LOCAL_CI=$LOCAL_CI
echo "Test result: $TEST_RESULT"
grep -A 1 'Final command line' $LOGDIR/${PREFIX}trial.log
if [ $TEST_RESULT == "OK" ] ; then
    rm -rf $LOGDIR/${PREFIX}vardir*
else
    grep -i -A 200 -E 'assertion|signal|\[FATAL\]|pure virtual method called' $LOGDIR/${PREFIX}vardir*/mysql.err
    if [[ $TEST_RESULT =~ BACKUP_FAILURE|UPGRADE_FAILURE|RECOVERY_FAILURE|DEADLOCKED ]] ; then
        echo "--- Errors in trial.log and mysql.err logs --------------"
        grep ERROR $LOGDIR/${PREFIX}trial.log $LOGDIR/${PREFIX}vardir*/mysql.err*
    fi
    if [[ $TEST_RESULT =~ BACKUP_FAILURE ]] ; then
        grep -i error $LOGDIR/${PREFIX}vardir*/mbackup_*
    elif [[ $TEST_RESULT =~ DATABASE_CORRUPTION ]] ; then
        echo "--- CORRUPTION in trial.log -----------------------------"
        grep DATABASE_CORRUPTION $LOGDIR/${PREFIX}trial.log
        echo "---------------------------------------------------------"
    elif [[ $TEST_RESULT =~ CRITICAL_FAILURE|ALARM|ENVIRONMENT_FAILURE|UNKNOWN_ERROR|N\/A ]] ; then
        echo "--- Beginning and end of trial.log ----------------------"
        head -n 5 $LOGDIR/${PREFIX}trial.log
        tail -n 100 $LOGDIR/${PREFIX}trial.log
        echo "---------------------------------------------------------"
    fi
    for cnf in $LOGDIR/${PREFIX}vardir*/my.cnf ; do
        echo "---" Config file in `dirname $cnf`
        cat $cnf
        echo "---------------------------------------------------------"
    done
    cd $LOGDIR
    tar zcf archive/${PREFIX}vardir.tar.gz ${PREFIX}vardir*
    tar zcf archive/${PREFIX}repro.tar.gz ${PREFIX}vardir*/mysql.log ${PREFIX}vardir*/mysql.err* ${PREFIX}postmortem
    rm -rf ${PREFIX}vardir*
    mv $LOGDIR/${PREFIX}* $LOGDIR/archive/
fi
