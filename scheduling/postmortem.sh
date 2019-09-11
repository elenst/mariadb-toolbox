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

vardirs=''
for v in $LOGDIR/${PREFIX}vardir* ; do
    vardirs="$vardir --vardir=$v"
done

`dirname $0`/../scripts/collect_rqg_result_info.sh $vardirs --test-log=$LOGDIR/${PREFIX}trial.log > $LOGDIR/${PREFIX}result_info 2>&1

SERVER_BRANCH=$SERVER_BRANCH TEST_ALIAS=$TEST_ALIAS TEST_RESULT=$TEST_RESULT TEST_ID=$TEST_ID LOCAL_CI=$LOCAL_CI perl $RQG_HOME/util/check_for_known_bugs.pl $SIGNATURES $LOGDIR/${PREFIX}result_info > $LOGDIR/${PREFIX}matches 2>&1

cat $LOGDIR/${PREFIX}matches
cat $LOGDIR/${PREFIX}result_info

i=0
for c in `find $LOGDIR/${PREFIX}vardir* -name core*` ; do
    binary=`file $c | sed -e "s/.*execfn: '\(.*\)', platform.*/\\1/"`
    core_pid=`echo $c | sed -e 's/.*core\.\([0-9]*\)$/\1/g'`
    if [[ $core_pid =~ "core" ]] ; then
        # substitution didn't happen
        core_pid=$i
        (( i=i+1 ))
    fi
    gdb --batch --eval-command="thread apply all bt full" $binary $c > $LOGDIR/${PREFIX}threads.$core_pid 2>&1
done

cd $LOGDIR
if [ "$TEST_RESULT" != "OK" ] ; then
    if ! grep 'STRONG matches' $LOGDIR/${PREFIX}matches || grep -E 'FOUND FIXED|\[Draft\]' $LOGDIR/${PREFIX}matches ; then
        tar zcf archive/${PREFIX}vardir.tar.gz ${PREFIX}*
        echo "Archived all data: " `ls -l archive/${PREFIX}vardir.tar.gz`
    else
        echo "Strong matches found, data discarded"
    fi
    tar zcf archive/${PREFIX}repro.tar.gz `find ${PREFIX}vardir* -name mysql.log` `find ${PREFIX}vardir* -name my.cnf` ${PREFIX}postmortem
fi
rm -rf ${PREFIX}vardir* $LOGDIR/${PREFIX}matches $LOGDIR/${PREFIX}result_info
mv $LOGDIR/${PREFIX}* $LOGDIR/archive/ > /dev/null 2>&1
