#!/bin/bash

# Expects in environment:
# SERVER_BRANCH
# TEST_ALIAS
# TEST_ID
# LOGDIR

PREFIX=$TEST_ID"_"

resline=`grep 'runall.* will exit with exit status' $LOGDIR/${PREFIX}trial.log || grep 'GenTest exited with exit status' $LOGDIR/${PREFIX}trial.log || grep 'GenTest will exit with exit status' $LOGDIR/${PREFIX}trial.log`;

TEST_RESULT=`echo $resline | sed -e 's/.*exit status STATUS_\([A-Z_]*\).*/\\1/g'`

LOCAL_CI=`hostname`

SIGNATURES="--signatures=$RQG_HOME/data/bug_signatures"
if [[ $SERVER_BRANCH =~ enterprise ]] ; then
    SIGNATURES="$SIGNATURES --signatures=$RQG_HOME/data/bug_signatures.es"
fi

echo SERVER_BRANCH=$SERVER_BRANCH TEST_ALIAS=$TEST_ALIAS TEST_RESULT=$TEST_RESULT TEST_ID=$TEST_ID LOCAL_CI=$LOCAL_CI
echo "Test result: $TEST_RESULT"
grep -A 1 'Final command line' $LOGDIR/${PREFIX}trial.log

for c in `find $LOGDIR/${PREFIX}vardir* -name core*` ; do
    binary=`file $c | sed -e "s/.*execfn: '\(.*\)', platform.*/\\1/"`
    core_pid=`echo $c | sed -e 's/.*core\.\([0-9]*\)$/\1/g'`
    gdb --batch --eval-command="thread apply all bt full" $binary $c > $LOGDIR/${PREFIX}threads.$core_pid 2>&1
    echo "---------------------------------------------------------"
    echo "--- Coredump $c"
    gdb --batch --eval-command="bt" $binary $c | grep -v 'New LWP'
    echo "---------------------------------------------------------"
done

SERVER_BRANCH=$SERVER_BRANCH TEST_ALIAS=$TEST_ALIAS TEST_RESULT=$TEST_RESULT TEST_ID=$TEST_ID LOCAL_CI=$LOCAL_CI perl $RQG_HOME/util/check_for_known_bugs.pl $SIGNATURES `find $LOGDIR/${PREFIX}vardir* -name mysql*.err*` `find $LOGDIR/${PREFIX}vardir* -name mbackup*.log` $LOGDIR/${PREFIX}threads.* --last=$LOGDIR/${PREFIX}trial.log

cd $LOGDIR
if [ $TEST_RESULT != "OK" ] ; then
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
    elif [[ $TEST_RESULT =~ CRITICAL_FAILURE|ALARM|ENVIRONMENT_FAILURE|UNKNOWN_ERROR|TEST_FAILURE|N\/A ]] ; then
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
    if ! grep 'STRONG matches' ${PREFIX}postmortem > /dev/null || grep -E 'FOUND FIXED|\[Draft\]' ${PREFIX}postmortem > /dev/null ; then
        tar zcf archive/${PREFIX}vardir.tar.gz ${PREFIX}*
        echo "Archived all data: " `ls -l archive/${PREFIX}vardir.tar.gz`
    else
        echo "Strong matches found, data discarded"
    fi
    tar zcf archive/${PREFIX}repro.tar.gz ${PREFIX}vardir*/mysql.log ${PREFIX}vardir*/my.cnf ${PREFIX}postmortem
fi
rm -rf ${PREFIX}vardir*
mv $LOGDIR/${PREFIX}* $LOGDIR/archive/
