#!/bin/bash

# Expects: 
# - HOME (mandatory)
# - BASEDIR (mandatory)
# - SERVER_BRANCH (mandatory)
# - RQG_HOME (mandatory)
# - LOGDIR (mandatory)
# - OLD_DATA_LOCATION (mandatory, where to download the data from)
# - OLD (mandatory, old version, major or minor)

# - TYPEs (optional, normal|crash|undo)
# - FILE_FORMATs (optional, Antelope|Barracuda)
# - INNODBs (optional, builtin|plugin)
# - PAGE_SIZEs (optional, 4K|8K|16K|32K|64K)
# - COMPRESSIONs (optional, on|off|<compression type>)
# - ENCRYPTIONs (optional, on|turn_on|off)

TYPEs=${TYPEs:-normal}
FILE_FORMATs=${FILE_FORMATs:-default}
INNODBs=${INNODBs:-builtin}
PAGE_SIZEs=${PAGE_SIZEs:-default}
COMPRESSIONs=${COMPRESSIONs:-default}
ENCRYPTIONs=${ENCRYPTIONs:-off}

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
echo "#   FILE_FORMATs:      $FILE_FORMATs"
echo "#   INNODBs:           $INNODBs"
echo "#   PAGE_SIZEs:        $PAGE_SIZEs"
echo "#   COMPRESSIONs:      $COMPRESSIONs"
echo "#   ENCRYPTIONs:       $ENCRYPTIONs"
echo "########################################################"


pidfile=/tmp/upgrade.pid
port=3308
socket=/tmp/upgrade.sock

start_server() {
  cd $BASEDIR
  rm -f $pidfile
  pid=
  echo "Starting server with options: $options $*"
  $BASEDIR/bin/mysqld --no-defaults $options $* &

  for s in 1 2 3 4 5 6 7 8 9 10 ; do
    if [ ! -e "$pidfile" ] ; then
      sleep 3
    else
      pid=`cat $pidfile`
      break
    fi
  done

  if [ -z "$pid" ] ; then
    echo "ERROR: Could not start the server"
    cat $VARDIR/mysql.err
    . $SCRIPT_DIR/soft_exit.sh 1
  fi

  case $SERVER_BRANCH in
  *10.4*)
    sudo $BASEDIR/bin/mysql --socket=$socket -e "SET PASSWORD=''"
    ;;
  esac
  cd -
}

shutdown_server() {
  $BASEDIR/bin/mysql --socket=$socket -uroot -e shutdown

  for s in 1 2 3 4 5 6 7 8 9 10 ; do
    if [ -e "$pidfile" ] ; then
      sleep 3
    else
      break
    fi
  done

  if [ -e "$pidfile" ] ; then
    echo "ERROR: Could not shut down the server"
    cat $VARDIR/mysql.err
    res=1
  fi
  cd -
}

check_tables() {
  if [ ! -e $VARDIR/check.sql ] ; then
    $BASEDIR/bin/mysql --socket=$socket -uroot --silent -e "select concat('CHECK TABLE ', table_schema, '.', table_name, ' EXTENDED;') FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE='InnoDB'" > $VARDIR/check.sql
  fi
  cat $VARDIR/check.sql | $BASEDIR/bin/mysql --socket=$socket -uroot --silent >> $VARDIR/check.output
  if grep -v "check.*status.*OK" $VARDIR/check.output ; then
    echo "ERROR: Not all tables are OK:"
    cat $VARDIR/check.output
    res=1
  fi
  
}


TRIAL=0
for ff in $FILE_FORMATs ; do
  for i in $INNODBs ; do
    for ps in $PAGE_SIZEs ; do
      for c in $COMPRESSIONs ; do
        for e in $ENCRYPTIONs ; do
          for t in $TYPEs ; do

            export TRIAL=$((TRIAL+1))
            export VARDIR=$LOGDIR/vardir$TRIAL
            export TRIAL_LOG=$VARDIR/trial${TRIAL}.log
            res=0

            echo "########################################################"
            echo "# TRIAL $TRIAL CONFIGURATION:"
            echo "#   Test type:   $t"
            echo "#   File format: $ff"
            echo "#   InnoDB:      $i"
            echo "#   Page size:   $ps"
            echo "#   Compression: $c"
            echo "#   Encryption:  $e"
            echo "########################################################"
            echo ""
            if [ -z "$e" ] || [ "$e" == "turn_on" ] ; then
              old_encryption=off
            else
              old_encryption=$e
            fi
            link=${OLD_DATA_LOCATION}/${OLD}/format-${ff}/innodb-${i}/${ps}/compression-${c}/encryption-${old_encryption}/${t}.tar.gz
            mkdir -p $VARDIR
            cd $VARDIR
            echo "Gettting $link"
            wget --quiet $link
            if [ "$?" != "0" ] ; then
              echo "ERROR: Failed to download the old data"
              . $SCRIPT_DIR/soft_exit.sh 1
            fi

            tar zxf ${t}.tar.gz
            datadir=$VARDIR/data
            if [ -e $datadir/mysql.log ] ; then
              mv $datadir/mysql.log $datadir/mysql.log_orig
            fi
            if [ -e $datadir/mysql.err ] ; then
              mv $datadir/mysql.err $datadir/mysql.err_orig
            fi

            options="--datadir=$datadir --basedir=$BASEDIR --pid-file=$pidfile --port=$port --socket=$socket --general-log --general-log-file=$VARDIR/mysql.log --log-error=$VARDIR/mysql.err"
            if [ "$ff" != "default" ] ; then
              options="$options --innodb-file-format=$ff"
            fi
            if [ "$i" == "plugin" ] ; then
              options="$options --ignore-builtin-innodb --plugin-load-add=ha_innodb"
            fi
            if [ "$ps" != "default" ] ; then
              options="$options --innodb-page-size=$ps"
            fi
            if [ "$c" != "default" ] ; then
              options="$options --innodb-compression-algorithm=$c"
            fi
            if [ "$e" == "on" ] || [ "$e" == "turn_on" ] ; then
              options="$options --plugin-load-add=file_key_management --file-key-management-filename=$TOOLBOX_DIR/data/keys.txt --innodb-encrypt-tables --innodb-encrypt-log"
            fi

            start_server
            check_tables

            $BASEDIR/bin/mysql_upgrade -uroot --socket=$socket
            if [ "$?" != "0" ] ; then
              echo "ERROR: Upgrade returned error"
              res=1
            fi

            shutdown_server
            mv $VARDIR/mysql.err $VARDIR/mysql.err.1

            start_server --loose-max-statement-time=10 --lock-wait-timeout=5 --innodb-lock-wait-timeout=3
            check_tables
            # After the test, tables might be different
            rm -f $VARDIR/check.sql

            cd $RQG_HOME
            set -o pipefail
            perl gentest.pl --dsn="dbi:mysql:host=127.0.0.1:port=$port:user=root:database=test" --grammar=conf/mariadb/generic-dml.yy --redefine=conf/mariadb/alter_table.yy --redefine=conf/mariadb/modules/admin.yy --redefine=conf/mariadb/instant_add.yy --threads=6 --queries=100M --duration=90 2>&1 | tee $TRIAL_LOG

            if [ "$?" != "0" ] ; then
              echo "ERROR: Test run returned error"
              res=1
            fi
            shutdown_server
            $ENV{SCRIPT_DIR}/collect_single_failure_info.sh
          done
        done
      done
    done
  done
done






