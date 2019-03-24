#!/bin/bash

# Expects: 
# - HOME (mandatory)
# - BASEDIR (mandatory)
# - SERVER_BRANCH (mandatory)
# - RQG_HOME (mandatory)
# - LOGDIR (mandatory)
# - OLD_DATA_LOCATION (mandatory, where to download the data from)
# - OLD (mandatory, old version, major or minor)

# - START_TIME (optional, seconds)
# - TYPEs (optional, normal|crash|undo)
# - FILE_FORMATs (optional, Antelope|Barracuda)
# - OLD_FILE_FORMATs (optional, Antelope|Barracuda)
# - NEW_FILE_FORMATs (optional, Antelope|Barracuda)
# - INNODBs (optional, builtin|plugin)
# - OLD_INNODBs (optional, builtin|plugin)
# - NEW_INNODBs (optional, builtin|plugin)
# - PAGE_SIZEs (optional, 4K|8K|16K|32K|64K)
#   (page size must remain the same, so there is no old/new here)
# - COMPRESSIONs (optional, on|off|<compression type>)
# - OLD_COMPRESSIONs (optional, on|off|<compression type>)
# - NEW_COMPRESSIONs (optional, on|off|<compression type>)
# - ENCRYPTIONs (optional, on|off)
# - OLD_ENCRYPTIONs (optional, on|off)
# - NEW_ENCRYPTIONs (optional, on|off)

# Having OLD_XX and NEW_XX indicates all combinations, e.g.
# OLD_COMPRESSIONS="none zlib" NEW_COMPRESSIONS="none zlib"
# would end up in 4 tests: none=>none, none=>zlib, zlib=>none, zlib=>zlib
# Having only XX indicates that the value remains intact, e.g.
# COMPRESSIONS="none zlib" would end up in 2 tests: non=>none, zlib=>zlib
#
# OLD_XX/NEW_XX values take precedence, if at least one is defined,
# then XX is ignored.

START_TIME=${START_TIME:-`date "+%s"`}
TYPEs=${TYPEs:-normal}
PAGE_SIZEs=${PAGE_SIZEs:-default}

if [ -z "$OLD_FILE_FORMATs" ] && [ -z "$NEW_FILE_FORMATs" ] ; then
  OLD_FILE_FORMATs=${FILE_FORMATs:-default}
  NEW_FILE_FORMATs=${FILE_FORMATs:-default}
else
  OLD_FILE_FORMATs=${OLD_FILE_FORMATs:-default}
  NEW_FILE_FORMATs=${NEW_FILE_FORMATs:-default}
  if [ -n "$FILE_FORMATs" ] ; then
    echo "WARNING: FILE_FORMATs=$FILE_FORMATs is ignored, because OLD and/or NEW values are specified"
    FILE_FORMATs=
  fi
fi

if [ -z "$OLD_INNODBs" ] && [ -z "$NEW_INNODBs" ] ; then
  OLD_INNODBs=${INNODBs:-default}
  NEW_INNODBs=${INNODBs:-default}
else
  OLD_INNODBs=${OLD_INNODBs:-default}
  NEW_INNODBs=${NEW_INNODBs:-default}
  if [ -n "$INNODBs" ] ; then
    echo "WARNING: INNODBs=$INNODBs is ignored, because OLD and/or NEW values are specified"
    INNODBs=
  fi
fi

if [ -z "$OLD_COMPRESSIONs" ] && [ -z "$NEW_COMPRESSIONs" ] ; then
  OLD_COMPRESSIONs=${COMPRESSIONs:-default}
  NEW_COMPRESSIONs=${COMPRESSIONs:-default}
else
  OLD_COMPRESSIONs=${OLD_COMPRESSIONs:-default}
  NEW_COMPRESSIONs=${NEW_COMPRESSIONs:-default}
  if [ -n "$COMPRESSIONs" ] ; then
    echo "WARNING: COMPRESSIONs=$COMPRESSIONs is ignored, because OLD and/or NEW values are specified"
    COMPRESSIONs=
  fi
fi

if [ -z "$OLD_ENCRYPTIONs" ] && [ -z "$NEW_ENCRYPTIONs" ] ; then
  OLD_ENCRYPTIONs=${ENCRYPTIONs:-default}
  NEW_ENCRYPTIONs=${ENCRYPTIONs:-default}
else
  OLD_ENCRYPTIONs=${OLD_ENCRYPTIONs:-default}
  NEW_ENCRYPTIONs=${NEW_ENCRYPTIONs:-default}
  if [ -n "$ENCRYPTIONs" ] ; then
    echo "WARNING: ENCRYPTIONs=$ENCRYPTIONs is ignored, because OLD and/or NEW values are specified"
    ENCRYPTIONs=
  fi
fi


echo "########################################################"
echo "# TEST CONFIGURATION:"
echo "#   HOME:              $HOME"
echo "#   BASEDIR:           $BASEDIR"
echo "#   SERVER_BRANCH:     $SERVER_BRANCH"
echo "#   RQG_HOME:          $RQG_HOME"
echo "#   LOGDIR:            $LOGDIR"
echo "#   OLD_DATA_LOCATION: $OLD_DATA_LOCATION"
echo "#   OLD [SERVER]:      $OLD"
echo "#   [TEST] TYPEs:      $TYPEs"
echo "#   OLD_FILE_FORMATs:  $OLD_FILE_FORMATs"
echo "#   NEW_FILE_FORMATs:  $NEW_FILE_FORMATs"
echo "#   OLD_INNODBs:       $OLD_INNODBs"
echo "#   NEW_INNODBs:       $NEW_INNODBs"
echo "#   PAGE_SIZEs:        $PAGE_SIZEs"
echo "#   OLD_COMPRESSIONs:  $OLD_COMPRESSIONs"
echo "#   NEW_COMPRESSIONs:  $NEW_COMPRESSIONs"
echo "#   OLD_ENCRYPTIONs:   $OLD_ENCRYPTIONs"
echo "#   NEW_ENCRYPTIONs:   $NEW_ENCRYPTIONs"
echo "########################################################"
echo ""

pidfile=/tmp/upgrade.pid
port=3308
export SOCKET=/tmp/upgrade.sock

add_result_to_summary() {
  export OLD t ps old_i old_f old_e old_c new_i new_f new_e new_c
  export test_duration=$((`date "+%s"`-$test_start))
  if [ -z "$res" ] ; then
    export status="N/A"
  elif [ "$res" == "0" ] ; then
    export status=OK
  else
    export status=FAIL
  fi
  perl -e 'print sprintf("| %2d | %12s | %6s | %7s | %7s | %9s | %7s | %8s | => | %7s | %9s | %7s | %8s | %4s | %4d |\n", $ENV{TRIAL}, $ENV{OLD}, $ENV{t}, $ENV{ps}, $ENV{old_i}, $ENV{old_f}, $ENV{old_e}, $ENV{old_c}, $ENV{new_i}, $ENV{new_f}, $ENV{new_e}, $ENV{new_c}, $ENV{status}, $ENV{test_duration})' >> $HOME/summary
}

terminate_if_error() {
  if [ "$1" != "0" ] ; then
    echo "FATAL ERROR: $2"
    if [ -e $pidfile ] ; then
      kill -9 `cat $pidfile`
    fi
    . $SCRIPT_DIR/collect_single_failure_info.sh
    res=1
    total_res=1
    add_result_to_summary
    if [ -e $VARDIR/failure_report ] ; then
      cat $VARDIR/failure_report
    fi
    continue
  fi
}

start_server() {
  echo "---------------"
  echo "Starting server with options: $options $*"
  cd $BASEDIR
  rm -f $pidfile
  pid=
  $BASEDIR/bin/mysqld --no-defaults $options $* &

  for s in 1 2 3 4 5 6 7 8 9 10 ; do
    if [ ! -e "$pidfile" ] ; then
      sleep 3
    else
      pid=`cat $pidfile`
      echo "Pid: $pid"
      break
    fi
  done

  if [ -z "$pid" ] ; then
    terminate_if_error 1 "Could not start the server"
  fi

  case $SERVER_BRANCH in
  *10.4*)
    sudo $BASEDIR/bin/mysql --socket=$SOCKET -e "SET PASSWORD=''"
    ;;
  esac
  cd - > /dev/null
}

shutdown_server() {
  echo "---------------"
  echo "Shutting down the server"
  $BASEDIR/bin/mysql --socket=$SOCKET -uroot -e shutdown

  pid=`cat $pidfile`
  for s in 1 2 3 4 5 6 7 8 9 10 ; do
    if [ -e "$pidfile" ] ; then
      sleep 3
    else
      echo "Pid file disappeared, apparently server got shut down"
      break
    fi
  done

  if [ -e "$pidfile" ] ; then
    echo "ERROR: Could not shut down the server"
    cat $VARDIR/mysql.err
    res=1
    kill -9 $pid
  fi
  cd - > /dev/null
}

check_tables() {
  echo "---------------"
  echo "Checking tables"
  if [ ! -e $VARDIR/check.sql ] ; then
    $BASEDIR/bin/mysql --socket=$SOCKET -uroot --silent -e "select concat('CHECK TABLE ', table_schema, '.', table_name, ' EXTENDED;') FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE='InnoDB'" > $VARDIR/check.sql
  fi
  cat $VARDIR/check.sql | $BASEDIR/bin/mysql --socket=$SOCKET -uroot --silent >> $VARDIR/check.output

  if grep -v "check.*status.*OK" $VARDIR/check.output ; then
    echo "ERROR: Not all tables are OK, see failure report"
    echo "-----------------------------------------" >> $VARDIR/failure_report
    echo "TABLE CHECK:" >> $VARDIR/failure_report
    cat $VARDIR/check.output >> $VARDIR/failure_report
    echo "ERROR: Not all tables are OK, see failure report"
    res=1
  else
    echo "All tables are reported to be OK"
  fi
}

TRIAL=0
total_res=0

echo Test date: `date '+%Y-%m-%d %H:%M:%S'` > $HOME/summary
echo "-------------------------------------------------------------------------------------------------------------------------------------------------" >> $HOME/summary
echo "| ## | OLD version  | type   | pg size | innodb  | file frmt | encrypt | compress |    |  innodb | file frmt | encrypt | compress |  res | time |" >> $HOME/summary
echo "-------------------------------------------------------------------------------------------------------------------------------------------------" >> $HOME/summary


for old_f in $OLD_FILE_FORMATs ; do
  for new_f in $NEW_FILE_FORMATs ; do
    if [ -n "$FILE_FORMATs" ] && [ "$old_f" != "$new_f" ] ; then
      echo ""
      echo "########################################################"
      echo "File format was requested to stay unchanged, the combination with $old_f => $new_f is skipped"
      continue
    fi
    for old_i in $OLD_INNODBs ; do
      for new_i in $NEW_INNODBs ; do
        if [ -n "$INNODBs" ] && [ "$old_i" != "$new_i" ] ; then
          echo ""
          echo "########################################################"
          echo "InnoDB type was requested to stay unchanged, the combination with $old_i => $new_i is skipped"
          continue
        fi
        for old_c in $OLD_COMPRESSIONs ; do
          for new_c in $NEW_COMPRESSIONs ; do
            if [ -n "$COMPRESSIONs" ] && [ "$old_c" != "$new_c" ] ; then
              echo ""
              echo "########################################################"
              echo "Compression was requested to stay unchanged, the combination with $old_c => $new_c is skipped"
              continue
            fi
            for old_e in $OLD_ENCRYPTIONs ; do
              for new_e in $NEW_ENCRYPTIONs ; do
                if [ -n "$ENCRYPTIONs" ] && [ "$old_e" != "$new_e" ] ; then
                  echo ""
                  echo "########################################################"
                  echo "Encryption was requested to stay unchanged, the combination with $old_e => $new_e is skipped"
                  continue
                fi
                for ps in $PAGE_SIZEs ; do
                  for t in $TYPEs ; do

                    res=0
                    export TRIAL=$((TRIAL+1))
                    export VARDIR=$LOGDIR/vardir$TRIAL
                    export TRIAL_LOG=$VARDIR/trial${TRIAL}.log

                    echo ""
                    echo "########################################################"
                    echo "# TRIAL $TRIAL CONFIGURATION:"
                    echo "#   Old version: $OLD"
                    echo "#   Test type:   $t"
                    echo "#   File format: $old_f => $new_f"
                    echo "#   InnoDB:      $old_i => $new_f"
                    echo "#   Page size:   $ps"
                    echo "#   Compression: $old_c => $new_c"
                    echo "#   Encryption:  $old_e => $new_e"
                    echo "########################################################"
                    echo ""

                    test_start=`date "+%s"`

                    # Don't run the test if we have less than 5 min left (more than 45 min has passed)
                    time_left=$((START_TIME+3000-test_start))
                    if [ $time_left -lt 300 ] ; then
                      echo "Too little time left ($time_left sec), skipping the test"
                      res=""
                      total_res=1
                      add_result_to_summary
                      continue
                    else
                      echo "$time_left sec left, running the test"
                    fi

                    link="${OLD_DATA_LOCATION}/${OLD}"
                    fname=${HOME}/$t
                    if [ "$old_f" != "default" ] ; then
                      link=${link}/format-${old_f}
                      fname=${fname}.format-${old_f}
                    fi
                    if [ "$old_i" != "default" ] ; then
                      link=${link}/innodb-${old_i}
                      fname=${fname}.innodb-${old_i}
                    fi
                    if [ "$ps" != "default" ] ; then
                      link=${link}/${ps}
                      fname=${fname}.${ps}
                    fi
                    if [ "$old_c" != "default" ] ; then
                      link=${link}/compression-${old_c}
                      fname=${fname}.compression-${old_c}
                    fi
                    if [ "$old_e" != "default" ] ; then
                      link=${link}/encryption-${old_e}
                      fname=${fname}.encryption-${old_e}
                    fi
                    link=${link}/${t}.tar.gz
                    fname=${fname}.tar.gz

                    mkdir -p $VARDIR
                    cd $VARDIR

                    echo "---------------"
                    echo "Link to download: $link"
                    if [ -e $fname ] ; then
                      echo "File $fname already exists"
                    else
                      echo "Downloading the file"
                      for i in 1 2 3 ; do
                        if time wget --quiet $link -O $fname ; then
                          break
                        fi
                      done
                    fi

                    if [ ! -s $fname ] ; then
                      terminate_if_error 1 "Failed to download the old data"
                    else
                      ls -l $fname
                    fi
                    echo "---------------"
                    echo "Extracting data"
                    tar zxf $fname
                    if [ "$?" != "0" ] ; then
                      terminate_if_error 1 "Failed to extract the old data"
                    else
                      du -sk data
                    fi
                    datadir=$VARDIR/data
                    if [ -e $datadir/mysql.log ] ; then
                      mv $datadir/mysql.log $datadir/mysql.log_orig
                    fi
                    if [ -e $datadir/mysql.err ] ; then
                      mv $datadir/mysql.err $datadir/mysql.err_orig
                    fi

                    options="--datadir=$datadir --basedir=$BASEDIR --pid-file=$pidfile --port=$port --socket=$SOCKET --general-log --general-log-file=$VARDIR/mysql.log --log-error=$VARDIR/mysql.err"
                    if [ "$new_f" != "default" ] ; then
                      options="$options --innodb-file-format=$new_f"
                    fi
                    if [ "$new_i" == "plugin" ] ; then
                      options="$options --ignore-builtin-innodb --plugin-load-add=ha_innodb"
                    fi
                    if [ "$ps" != "default" ] ; then
                      options="$options --innodb-page-size=$ps"
                    fi
                    if [ "$new_c" != "default" ] ; then
                      options="$options --innodb-compression-algorithm=$new_c"
                    fi
                    if [ "$new_e" == "on" ] ; then
                      options="$options --plugin-load-add=file_key_management --file-key-management-filename=$TOOLBOX_DIR/data/keys.txt --innodb-encrypt-tables --innodb-encrypt-log"
                    fi

                    start_server
                    check_tables

#                    echo "---------------"
#                    echo "Checking if workarounds for known problems are needed"
#                    . $SCRIPT_DIR/innodb_static_upgrade_workarounds.sh
#                    terminate_if_error $? "Problem occurred while applying workarounds"

                    echo "---------------"
                    echo "Running mysql_upgrade"
                    $BASEDIR/bin/mysql_upgrade -uroot --socket=$SOCKET > /tmp/mysql_upgrade.log 2>&1
                    if [ "$?" != "0" ] ; then
                      echo "ERROR: mysql_upgrade failed, see failure report"
                      echo "-----------------------------------------" >> $VARDIR/failure_report
                      echo "MySQL UPGRADE:" >> $VARDIR/failure_report
                      cat /tmp/mysql_upgrade.log >> $VARDIR/failure_report
                      echo "-----------------------------------------" >> $VARDIR/failure_report
                      terminate_if_error 1 "mysql_upgrade returned error"
                    else
                      echo "mysql_upgrade apparently succeeded"
                    fi

                    shutdown_server
                    mv $VARDIR/mysql.err $VARDIR/mysql.err.1

                    start_server --loose-max-statement-time=10 --lock-wait-timeout=5 --innodb-lock-wait-timeout=3
                    check_tables
                    # After the test, tables might be different
                    rm -f $VARDIR/check.sql

                    cd $RQG_HOME
                    set -o pipefail
                    echo "---------------"
                    echo "Running post-upgrade DML/DDL"
                    time perl gentest.pl --dsn="dbi:mysql:host=127.0.0.1:port=$port:user=root:database=test" --grammar=conf/mariadb/generic-dml.yy --redefine=conf/mariadb/alter_table.yy --redefine=conf/mariadb/modules/admin.yy --redefine=conf/mariadb/instant_add.yy --threads=6 --queries=100M --duration=60 --seed=time 2>&1 > $TRIAL_LOG 2>&1
                    if [ "$?" != "0" ] ; then
                      echo "Post-upgrade DML/DDL failed, see failure report"
                      echo "-----------------------------------------" >> $VARDIR/failure_report
                      echo "TRIAL LOG:" >> $VARDIR/failure_report
                      cat $TRIAL_LOG >> $VARDIR/failure_report
                      echo "-----------------------------------------" >> $VARDIR/failure_report
                      res=1
                    else
                      echo "Post-upgrade DML/DDL succeeded"
                    fi

                    shutdown_server

                    if [ "$res" == "0" ] ; then
                      echo "Upgrade test will exit with exit status STATUS_OK" >> $TRIAL_LOG
                    else
                      echo "Upgrade test will exit with exit status STATUS_UPGRADE_FAILURE" >> $TRIAL_LOG
                      total_res=$res
                    fi

                    echo "---------------"
                    . $SCRIPT_DIR/collect_single_failure_info.sh
                    add_result_to_summary
                    if [ -e $VARDIR/failure_report ] ; then
                      cat $VARDIR/failure_report
                    fi
                    echo ""
                    echo "End of trial $TRIAL, duration $test_duration"
                  done
                done
              done
            done
          done
        done
      done
    done
  done
done
echo "-------------------------------------------------------------------------------------------------------------------------------------------------" >> $HOME/summary
echo "" >> $HOME/summary

cat $HOME/summary
echo "TOTAL RESULT: $total_res"
. $SCRIPT_DIR/soft_exit.sh $total_res



