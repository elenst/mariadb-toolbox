#!/usr/bin/bash
#
#  Copyright (c) 2017, 2019, MariaDB
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
# - RQG_HOME
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

function load_failure
{
  date
  ls -l ${LOGDIR}/${ARCHDIR}*.tar.gz

#  for f in logs datadirs coredumps ; do
  for f in logs ; do

    if [ -e ${LOGDIR}/${ARCHDIR}_${f}.tar.gz ] ; then

      time $MYSQL --local-infile --max-allowed-packet=1G --host=$DB_HOST --port=$DB_PORT -u$DB_USER -p$DBP -e "LOAD DATA LOCAL INFILE \"${LOGDIR}/${ARCHDIR}_${f}.tar.gz\" REPLACE INTO TABLE travis.${f} CHARACTER SET BINARY FIELDS TERMINATED BY 'xxxxxthisxxlinexxxshouldxxneverxxeverxxappearxxinxxanyxxfilexxxxxxxxxxxxxxxxxxxxxxxx' ESCAPED BY '' LINES TERMINATED BY 'XXXTHISXXLINEXXSHOULDXXNEVERXXEVERXXAPPEARXXINXXANYXXFILEXXXXXXXXXXXXXXXXXXXX' (data) SET build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL, command_line = \"$TRIAL_CMD\", server_branch = \"$SERVER_BRANCH\", server_revision = \"$SERVER_REVISION\", test_branch = \"$RQG_BRANCH\", test_revision = \"$RQG_REVISION\""

      if [ "$?" != "0" ] ; then
        echo "ERROR: Failed to load $f for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
      else
        echo "Loaded $f for build_id = $TRAVIS_BUILD_NUMBER, job_id = $TRAVIS_JOB, trial_id = $TRIAL"
      fi
    fi

  done
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
  gdb --batch --eval-command="thread apply all bt" $binary $coredump > $datadir/threads
  gdb --batch --eval-command="thread apply all bt full" $binary $coredump > $datadir/threads_full
  cp $binary $datadir/
}

###### "main"

TRAVIS_JOB=`echo $TRAVIS_JOB_NUMBER | sed -e 's/.*\.//'`
export TEST_ID="${TRAVIS_BUILD_NUMBER}.${TRAVIS_JOB}.${TRIAL}"

# Only do the job if initial checks passed

if [ "$res" == "0" ] ; then

  echo "Collecting single result info for logdir $LOGDIR"

  VARDIR="${VARDIR:-$LOGDIR/vardir}"
  TRIAL_LOG="${TRIAL_LOG:-$LOGDIR/trial.log}"
  ARCHDIR="arch_${TRAVIS_JOB_NUMBER}.${TRIAL}"
  rm -rf ${LOGDIR}/${ARCHDIR} 
  mkdir -p ${LOGDIR}/${ARCHDIR}/logs

  TRIAL_CMD=""
  TRIAL_STATUS=""
  result_collection_options=""

  if [ -e $TRIAL_LOG ] ; then
    TRIAL_STATUS=`grep 'will exit with exit status' $TRIAL_LOG | tail -1 | sed -e 's/.*will exit with exit status STATUS_\([A-Z_]*\).*/\1/'`
    TRIAL_CMD=`grep -A 1 'Final command line:' $TRIAL_LOG`
    cp $TRIAL_LOG ${LOGDIR}/${ARCHDIR}/logs/
    result_collection_options="--test-log=$TRIAL_LOG"
  else
    echo "$TRIAL_LOG does not exist"
    TRIAL_STATUS=UNKNOWN_FAILURE
  fi

  for v in ${VARDIR}* ; do
    result_collection_options="$result_collection_options --vardir=$v"
  done

  echo "TEST RESULT: $TRIAL_STATUS"
  echo ""
  export TEST_RESULT=$TRIAL_STATUS

  $SCRIPT_DIR/../scripts/collect_rqg_result_info.sh $result_collection_options > ${LOGDIR}/${ARCHDIR}/result_info 2>&1

  if [ -n "$RQG_HOME" ] ; then
    signatures=$RQG_HOME/data/bug_signatures
    check_path=$RQG_HOME/util
  else
    echo "WARNING: We are using an outdated version of bug signatures and check script"
    signatures=$SCRIPT_DIR/../data/bug_signatures
    check_path=$SCRIPT_DIR
  fi
  perl $check_path/check_for_known_bugs.pl --signatures=$signatures ${VARDIR}*/mysql.err* ${LOGDIR}/${ARCHDIR}/result_info

  echo
  echo '#' ${TRAVIS_BUILD_NUMBER} ${TRAVIS_JOB} ${TRIAL}
  echo Server: $SERVER_BRANCH `echo $SERVER_REVISION | cut -c 1-7`
  echo Tests: $RQG_BRANCH `echo $RQG_REVISION | cut -c 1-7` Toolbox: $TOOLBOX_BRANCH `echo $TOOLBOX_REVISION | cut -c 1-7`
  echo
  echo $TRIAL_CMD
  echo

  cat ${LOGDIR}/${ARCHDIR}/result_info
  
  # Success processing
  if [[ "$TRIAL_STATUS" == "OK" ]] ; then
    res=0
  elif [[ "$TRIAL_STATUS" == "CUSTOM_OUTCOME" ]] ; then
    res=0
  else
    res=1
  fi

  # Storing the data
  for dname in ${VARDIR}*
  do
    for fname in $dname/mysql.err* $dname/boot.log
    do
      if [ -e $fname ] ; then
        mkdir -p ${LOGDIR}/${ARCHDIR}/logs/${dname}
        cp $fname ${LOGDIR}/${ARCHDIR}/logs/${dname}/
      fi
    done

    for fname in ${VARDIR}*/mbackup_*.log
    do
      mkdir -p ${LOGDIR}/${ARCHDIR}/logs/${dname}
      cp $fname ${LOGDIR}/${ARCHDIR}/logs/${dname}/
    done

    # Storing general logs
    for fname in $dname/mysql.log
    do
      if [ -e $fname ] ; then
        mkdir -p ${LOGDIR}/${ARCHDIR}/logs/${dname}
        cp $fname ${LOGDIR}/${ARCHDIR}/logs/${dname}/
      fi
    done

    # Checking for coredump in the _orig datadir
    if [ -e $dname/data_orig/core ] ; then
      datadir=$dname/data_orig
      coredump=$datadir/core
      # Since it's in the _orig dir, it is definitely from the old server
      bname=$HOME/old
      process_coredump
      mkdir -p ${LOGDIR}/${ARCHDIR}/coredumps
      mv $coredump ${LOGDIR}/${ARCHDIR}/coredumps/core.orig
      if [ -e $datadir/mysqld ] ; then
        mv $datadir/mysqld ${LOGDIR}/${ARCHDIR}/coredumps/mysqld.orig
      fi
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
      mkdir -p ${LOGDIR}/${ARCHDIR}/coredumps
      mv $coredump ${LOGDIR}/${ARCHDIR}/coredumps/
      if [ -e $datadir/mysqld ] ; then
        mv $datadir/mysqld ${LOGDIR}/${ARCHDIR}/coredumps/mysqld
      fi
    fi
      
    mkdir -p $LOGDIR/$ARCHDIR/datadirs/
    mv $dname $LOGDIR/$ARCHDIR/datadirs/
  done

  cd $LOGDIR
  if [ -e $ARCHDIR/logs ] ; then
    tar zcf ${ARCHDIR}_logs.tar.gz $ARCHDIR/logs
  fi
  if [ -e $ARCHDIR/coredumps ] ; then
    tar zcf ${ARCHDIR}_coredumps.tar.gz $ARCHDIR/coredumps
  fi
  if [ -e $ARCHDIR/datadirs ] ; then
    tar zcf ${ARCHDIR}_datadirs.tar.gz $ARCHDIR/datadirs
  fi

  load_failure
fi

rm -rf ${LOGDIR}/${ARCHDIR}*

cd $OLDDIR
. $SCRIPT_DIR/soft_exit.sh $res
