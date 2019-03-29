########################################################################
# Generate "old" data for InnoDB upgrade tests
########################################################################

# GA versions: 5.5.23 10.0.10 10.1.8 10.2.6 10.3.7
#
# Exceptions:
# 10.0.10 hangs on shutdown after innodb-force-recovery=3, can't generate "undo"
#
#
#####################################
# Full procedure for generating data:
#
# If the data needs to be modified (e.g. more/less tables, more/less fields, etc.),
# then first re-generate SQL files:
#
# - Run RQG as below. The grammar should be anything innocent, e.g. "SELECT 1".
#   The point is to generate the data and leave server alive.
#   (skip *page-compression*zz for 5.5/10.0, use all for 10.1+)
# perl ./runall-new.pl --gendata=conf/mariadb/upgrade/innodb.zz --gendata=conf/mariadb/upgrade/innodb-partition.zz --gendata=conf/mariadb/upgrade/innodb-page-compression.zz --gendata=conf/mariadb/upgrade/innodb-page-compression-partition.zz --grammar=1.yy --queries=100 --threads=1 --basedir=/data/releases/10.2.6 --vardir=/dev/shm/vardir --skip-shutdown
# - Run mysqldump as below (choose the name for the SQL file accordingly)
#   /data/releases/10.0.10/bin/mysqldump -uroot --protocol=tcp --port=19300 --extended-insert test > conf/mariadb/upgrade/innodb-all.sql
# - Shut down the server  
#
# When/if SQL files are already generated:
# - Check hardcoded values below (locations etc.)
# - Run
#   . conf/mariadb/upgrade/innodb_data_generation.sh --version=10.2.6 --normal --crash --undo 2>&1 | tee ./upgr.out
#   with the corresponding server version.
# - Check upgr.out for errors, to make sure all data files are generated
# - If needed, re-run individual combinations until they succeeded
# - Remove all 'data' folders from within <logdir>/<version> 
# - Upload <logdir>/<version> to FTP
#

curdir=`pwd`

release_location=/data/releases
rqg_home=/data/src/rqg
logdir=/data/logs/upgrade_data
port=8306
pidfile=/tmp/upgrade.pid
file_format=default
innodb=default
page_size=default
compression=default
encryption=default
file_per_table=default
normal=""
crash=""
undo=""

for o in "$@" ; do
  val=`echo "$o" | sed -e "s;--[^=]*=;;"`
  case "$o" in
    --version*=*) versions=$val ;;
    --normal) normal=1 ;;
    --crash)  crash=1 ;;
    --undo)   undo=1 ;;
    --release[-_]location=*) release_location=$val ;;
    --rqg[-_]home=*) rqg_home=$val ;;
    --logdir=*) logdir=$val ;;
    --port=* ) port=$val ;;
    --file[-_]format=*) opt_file_format=$val ;;
    --innodb=*) opt_innodb=$val ;;
    --page[-_]size=*) opt_page_size=$val ;;
    --compression=*) opt_compression=$val ;;
    --encryption=*) opt_encryption=$val ;;
    --file_per_table=*) opt_file_per_table=$val ;;
  esac
done

start_server() {
  echo "Starting server with $options $*"
  cd $basedir
  rm -f $pidfile
  $basedir/bin/mysqld $options $* &
  for a in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ; do
    if [ -e $pidfile ] ; then
      pid=`cat $pidfile`
      echo "Server pid: $pid"
      break
    else
      sleep 3
    fi
  done
  if [ ! -e $pidfile ] ; then
    echo "ERROR: Could not start server, skipping this combination"
    continue
  fi
}

kill_server() {
  pid=$1
  sig=$2
  echo "Killing server $pid with signal $sig"
  kill $sig $pid
  for a in 1 2 3 4 5 6 7 8 9 10 ; do
    for b in 1 2 3 4 5 6 ; do
      if kill -0 $pid > /dev/null 2>&1 ; then
        echo "Server is still alive"
        sleep 1
      else
        break
      fi
    done
  done
  if kill -0 $pid > /dev/null 2>&1 ; then
    echo "ERROR: Could not stop server, skipping this combination"
    kill -9 $pid
    continue
  fi
}

for v in $versions ; do
  case $v in
  5.5*)
    file_format=${opt_file_format:-"Antelope Barracuda"}
    file_per_table=${opt_file_per_table:-"off on"}
    innodb=${opt_innodb:-"builtin plugin"}
    sql_files="innodb-no-page-compression-5.5.sql"
    ;;
  10.0*)
    file_format=${opt_file_format:-"Antelope Barracuda"}
    innodb=${opt_innodb:-"builtin plugin"}
    page_size=${opt_page_size:-"16K 8K 4K"}
    sql_files="innodb-no-page-compression.sql"
# Workaround for MDEV-18084
#    sql_files="innodb-no-page-compression-no-virtual-columns.sql"
# Workaround for MDEV-18960
#    sql_files="innodb-no-page-compression-no-generated-columns.sql"
    ;;
  10.1*)
    file_format=${opt_file_format:-"Antelope Barracuda"}
    innodb=${opt_innodb:-"builtin plugin"}
    page_size=${opt_page_size:-"16K 8K 4K 32K 64K"}
    compression=${opt_compression:-"none zlib"}
    encryption=${opt_encryption:-"off on"}
    sql_files="innodb-all.sql"
# Workaround for MDEV-18084
#    sql_files="innodb-all-no-virtual-columns.sql"
# Workaround for MDEV-18960
#    sql_files="innodb-all-no-generated-columns.sql"
# Workaround for MDEV-19016: enable instead of innodb-all for 32K-64K on Barracuda:
#    sql_files="innodb-no-format-compressed.sql"
    ;;
  10.2*)
    file_format=${opt_file_format:-"Antelope Barracuda"}
    page_size=${opt_page_size:-"16K 8K 4K 32K 64K"}
    compression=${opt_compression:-"none zlib"}
    encryption=${opt_encryption:-"off on"}
    sql_files="innodb-all.sql"
    ;;
  10.[34]*)
    page_size=${opt_page_size:-"16K 8K 4K 32K 64K"}
    compression=${opt_compression:-"none zlib"}
    encryption=${opt_encryption:-"off on"}
    sql_files="innodb-all.sql"
    ;;
  esac

  for f in $file_format ; do
    for i in $innodb ; do
      for ft in $file_per_table ; do
        for p in $page_size ; do
          for c in $compression ; do
            for e in $encryption ; do
              basedir=$release_location/$v
              options="--basedir=$basedir --pid-file=$pidfile --port=$port --general-log --general-log-file=mysql.log --log-error=mysql.err"
              datapath="$logdir/${v}"
              if [ "$f" != "default" ] ; then
                datapath="$datapath/format-${f}"
                options="$options --innodb-file-format=$f"
              fi
              if [ "$i" != "default" ] ; then
                datapath="$datapath/innodb-${i}"
                if [ "$i" == "plugin" ] ; then
                  options="$options --ignore-builtin-innodb --plugin-load=ha_innodb"
                fi
              fi
              if [ "$ft" != "default" ] ; then
                datapath="$datapath/file_per_table-${ft}"
                options="$options --innodb-file-per-table=$ft"
              fi
              if [ "$p" != "default" ] ; then
                datapath="$datapath/${p}"
                options="$options --innodb-page-size=$p"
              fi
              if [ "$c" != "default" ] ; then
                datapath="$datapath/compression-${c}"
                options="$options --innodb-compression-algorithm=$c"
              fi
              if [ "$e" != "default" ] ; then
                datapath="$datapath/encryption-${e}"
                if [ "$e" == "on" ] ; then
                  options="$options --plugin-load-add=file_key_management --file-key-management-filename=$basedir/mysql-test/std_data/keys.txt --innodb-encrypt-tables --innodb-encrypt-log"
                fi
              fi
              datadir=$datapath/data
              options="--datadir=$datadir $options"

              echo ""
              echo "-----------------------------------------------------"
              echo "Combination: $datapath"
              echo ""
              echo "Options: $options"
              rm -rf $datadir
              rm -f $pidfile
              mkdir -p $datadir
              cd $basedir
              echo ""
              echo "Running bootstrap"
              scripts/mysql_install_db $options > $datadir/boot.log 2>&1
              echo "Result $?"
              start_server
              echo "Generating data for normal upgrade"
              for s in $sql_files ; do
                echo "Loading file $s"
                cat $rqg_home/conf/mariadb/upgrade/$s | bin/mysql --force --show-warnings -uroot --protocol=tcp --port=$port test > /tmp/load.log 2>&1
                # We allow certain warnings and errors, e.g. ROW_FORMAT=COMPRESSED cannot be used with 32K/64K page sizes,
                # not all formats are supported with Antelope, etc.
                # but we want to see the warnings, apart from the numerous obvious/useless ones
                echo "--- Errors/warnings generated while loading the file"
                grep -v 'The value specified for generated column' /tmp/load.log | grep -v 'The value specified for computed column' | grep -v 'ERROR 1146' | grep -v 'Got error 140'
                echo "---"
              done
              sleep 3
              kill_server $pid
              if [ -n "$normal" ] ; then
                cd $datapath
                rm -f normal.tar.gz
                echo "Generating normal data archive"
                tar zcf normal.tar.gz data
                cd - > /dev/null
              fi
              echo ""
              if [ -n "$crash" ] || [ -n "$undo" ] ; then
                start_server
                echo "Generating workflow for crash/undo upgrade"
                cd $rqg_home
                perl gentest.pl --dsn="dbi:mysql:user=root:host=127.0.0.1:port=$port:database=test" --grammar=conf/mariadb/generic-dml.yy --threads=8 --duration=60 --queries=100M > $basedir/gentest.log 2>&1 &
                sleep 40
                kill_server $pid -9
              fi
              if [ -n "$crash" ] ; then
                cd $datapath
                rm -f crash.tar.gz
                echo "Generating crash data archive"
                tar zcf crash.tar.gz data
                cd - > /dev/null
              fi
              echo ""
              if [ -n "$undo" ] ; then
                start_server --innodb-force-recovery=3
                echo "Generating data for undo upgrade"
                sleep 10
                kill_server $pid
                cd $datapath
                rm -f undo.tar.gz
                echo "Generating undo data archive"
                tar zcf undo.tar.gz data
                cd - > /dev/null
              fi
              cd $datapath
              echo "For $datapath the following files have been generated:"
              ls *.tar.gz
              cd - > /dev/null
            done
          done
        done
      done
    done
  done
  
done

cd $curdir
