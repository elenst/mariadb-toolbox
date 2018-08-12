#!/usr/bin/bash
#
#  Copyright (c) 2017, 2018, MariaDB
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

# From environment:
# Mandatory:
# - BASEDIR
# - LOGDIR
# Optional:
# - TRIAL
# - SERVER_BRANCH
# - SERVER_REVISION
# - RQG_BRANCH
# - RQG_REVISION
# - CMAKE_OPTIONS

OLDDIR=`pwd`
res=0

###### Initial checks

if [ -z "$LOGDIR" ] ; then
  echo "ERROR: Logdir is not defined, cannot process logs"
  res=1
elif [ -z "$BASEDIR" ] ; then
  echo "ERROR: Basedir is not defined, cannot process logs"
  res=1
elif [ -e "$BASEDIR/bin/mysql" ] ; then
  MYSQL=$BASEDIR/bin/mysql
elif [ -e "$BASEDIR/client/mysql" ] ; then
  MYSQL=$BASEDIR/client/mysql
else
  echo "ERROR: MySQL client not found, cannot process logs"
  res=1
fi

###### Functions

function soft_exit
{
  cd $OLDDIR
#  return $res
  return 0
}

function insert_success
{
   $MYSQL --host=$DB_HOST --port=$DB_PORT -u$DB_USER -p$DBP -e "REPLACE INTO travis.success SET build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL, travis_branch = \"$TRAVIS_BRANCH\", result = \"$TRIAL_RESULT\", status = \"$TRIAL_STATUS\", command_line = \"$TRIAL_CMD\", server_branch = \"$SERVER_BRANCH\", server_revision = \"$SERVER_REVISION\", cmake_options = \"$CMAKE_OPTIONS\", test_branch = \"$RQG_BRANCH\", test_revision = \"$RQG_REVISION\""

  if [ "$?" != "0" ] ; then
    echo "ERROR: Failed to insert the successful result $TRIAL_RESULT for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
    res=1
  else
    echo "Inserted the successful result $TRIAL_RESULT for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
  fi
}

function load_failure
{
  ls -l ${LOGDIR}/${ARCHDIR}.tar.gz

  $MYSQL --local-infile --host=$DB_HOST --port=$DB_PORT -u$DB_USER -p$DBP -e "LOAD DATA LOCAL INFILE \"${LOGDIR}/${ARCHDIR}.tar.gz\" REPLACE INTO TABLE travis.failure CHARACTER SET BINARY FIELDS TERMINATED BY 'xxxxxthisxxlinexxxshouldxxneverxxeverxxappearxxinxxanyxxfilexxxxxxxxxxxxxxxxxxxxxxxx' ESCAPED BY '' LINES TERMINATED BY 'XXXTHISXXLINEXXSHOULDXXNEVERXXEVERXXAPPEARXXINXXANYXXFILEXXXXXXXXXXXXXXXXXXXX' (data) SET build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL, travis_branch = \"$TRAVIS_BRANCH\", result = \"$TRIAL_RESULT\", status = \"$TRIAL_STATUS\", command_line = \"$TRIAL_CMD\", server_branch = \"$SERVER_BRANCH\", server_revision = \"$SERVER_REVISION\", cmake_options = \"$CMAKE_OPTIONS\", test_branch = \"$RQG_BRANCH\", test_revision = \"$RQG_REVISION\""

  if [ "$?" != "0" ] ; then
    echo "ERROR: Failed to insert the failure $TRIAL_RESULT and load ${LOGDIR}/${ARCHDIR}.tar.gz for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
    res=1
  else
    echo "Inserted the failure $TRIAL_RESULT and loaded ${LOGDIR}/${ARCHDIR}.tar.gz for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
  fi
}

function process_coredump
{
  # Expects:
  # - $bname for binary directory
  # - $coredump for the path to a core file
  # - $datadir for the datadir
  
  if [ -e $bname/bin/mysqld ] ; then
    binary=$bname/bin/mysqld
  elif [ -e $bname/sql/mysqld ] ; then
    binary=$bname/sql/mysqld
  fi
  
  ldd $binary
  
  echo
  echo "------------------- $coredump --------------------------"
  echo "------------------- Generated by $binary"
  echo
  gdb --batch --eval-command="thread apply 1 bt" $binary $coredump
  echo
  echo "-------------------"
  echo
  
  gdb --batch --eval-command="thread apply all bt" $binary $coredump > $datadir/threads
  gdb --batch --eval-command="thread apply all bt full" $binary $coredump > $datadir/threads_full
  cp $binary $datadir/
}

###### "main"

TRIAL_COUNT="${TRIAL_COUNT:-0}"
TRIAL_COUNT=$((TRIAL_COUNT+1))

# Only use the internal counter if the external value doesn't exist or doesn't get updated
if [[ "$TRIAL" -lt "$TRIAL_COUNT" ]] ; then
    TRIAL=$TRIAL_COUNT
fi

# Only do the job if initial checks passed

if [ "$res" == "0" ] ; then

  VARDIR="${VARDIR:-$LOGDIR/vardir}"
  TRIAL_LOG="${TRIAL_LOG:-$LOGDIR/trial.log}"
  ARCHDIR="logs_${TRAVIS_JOB_NUMBER}.${TRIAL}"
  TRAVIS_JOB=`echo $TRAVIS_JOB_NUMBER | sed -e 's/.*\.//'`

  TRIAL_CMD=""
  TRIAL_RESULT=""
  TRIAL_STATUS=""

  rm -rf ${LOGDIR}/${ARCHDIR} && mkdir ${LOGDIR}/${ARCHDIR}

  echo ""
  echo "============================= Trial $TRIAL results ============================="

  if [ -e $TRIAL_LOG ] ; then
    TRIAL_STATUS=`grep 'will exit with exit status' $TRIAL_LOG | sed -e 's/.*will exit with exit status STATUS_\([A-Z_]*\).*/\1/'`
    TRIAL_CMD=`grep -A 1 'Final command line:' $TRIAL_LOG`
    cp $TRIAL_LOG ${LOGDIR}/${ARCHDIR}/
  else
    echo "$TRIAL_LOG does not exist"
  fi

  echo "Status: $TRIAL_STATUS"
  
  # Success processing
  if [[ "$TRIAL_STATUS" == "OK" ]] ; then
    TRIAL_RESULT=PASS
    insert_success

  # Failure processing
  else

    perl $HOME/mariadb-tests/scripts/check_for_known_bugs.pl ${VARDIR}*/mysql.err $TRIAL_LOG

    echo
    echo '#' ${TRAVIS_BUILD_NUMBER},${TRAVIS_JOB},${TRIAL} / ${TRAVIS_BUILD_NUMBER}.${TRAVIS_JOB}.${TRIAL}
    echo Server: $SERVER_BRANCH $SERVER_REVISION
    echo Tests: $RQG_BRANCH $RQG_REVISION
    echo
    echo $TRIAL_CMD
    echo

    for dname in ${VARDIR}*
    do
      # Quoting bootstrap log all existing error logs
      for fname in $dname/mysql.err* $dname/boot.log
      do
        if [ -e $fname ] ; then
          echo "------------------- $fname -----------------------------"
          cat $fname | grep -v "\[Note\]" | grep -v "\[Warning\]" | grep -v "^$" | cut -c 1-4096
          echo "-------------------"
        fi
      done

      # Checking for coredump in the _orig datadir
      if [ -e $dname/data_orig/core ] ; then
        datadir=$dname/data_orig
        coredump=$datadir/core
        # Since it's in the _orig dir, it is definitely from the old server
        bname=$HOME/old
        process_coredump
      fi

      # Checking for coredump in the datadir
      if [ -e $dname/data/core ] ; then
        datadir=$dname/data
        coredump=$datadir/core
        
        # It can be both from the old and the new server, depending on
        # whether it is an upgrade test, and if it is, on when
        # the test failed. If there is also 'data_orig', then 'data'
        # belongs to the new server; if there is no 'data_orig' and 'old'
        # server exists, then it's an upgrade test and the core belongs to
        # the old server; otherwise it belongs to the new server
        
        if [ -e $dname/data_orig ] ; then
          bname=$BASEDIR
        elif [ -e $HOME/old ] ; then
          bname=$HOME/old
        else
          bname=$BASEDIR
        fi

        process_coredump
      fi
      
      mv $dname $LOGDIR/$ARCHDIR/
    done

    cd $LOGDIR
    tar zcf $ARCHDIR.tar.gz $ARCHDIR
    if [[ "$TRIAL_STATUS" == "CUSTOM_OUTCOME" ]] ; then
      TRIAL_RESULT=UNKNOWN
    else
      TRIAL_RESULT=FAIL
    fi
    load_failure
  fi

  rm -rf ${LOGDIR}/${ARCHDIR}*
  echo "============================= End of trial $TRIAL results ======================="
fi


soft_exit
