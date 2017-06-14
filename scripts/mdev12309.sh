# Attention! This test is not portable
if [ -z "$1" ]; then
	echo "Usage: $0 <test number> [<new server> [<old server> [<old clean dir>]]]"
	exit 1
fi

blddir=/data/bld
testnum=$1
new_server=$2
old_server=$3
old_server_cleandir=$4
if [ -z "$4" ] ; then
  old_server_cleandir=/data/data.clean.mysql-5.7
fi
if [ -z "$3" ] ; then
  old_server=/data/bld/mysql-5.7
fi
if [ -z "$2" ] ; then
  new_server=/data/bld/10.2
fi

ml="bin/mysql -uroot --protocol=tcp test"
mupgrade="bin/mysql_upgrade -uroot --protocol=tcp"

case $testnum in
  "1")
	echo "-----------------------------------------------"
	echo "Test $testnum: Migration of an empty tablespace"
	echo "-----------------------------------------------"
	sql_old="CREATE TABLESPACE space1 ADD DATAFILE 'space1f1.ibd'"
	sql_new="CREATE TABLE t1 (i int) TABLESPACE space1"
	sql_new="$sql_new ; SHOW CREATE TABLE t1"
	sql_new="$sql_new ; INSERT INTO t1 VALUES (1),(2)"
	sql_new="$sql_new ; SELECT * FROM t1"
  ;;
  "2")
	echo "-----------------------------------------------"
	echo "Test $testnum: Migration of one tablespace with a simple table"
	echo "-----------------------------------------------"
	sql_old="CREATE TABLESPACE space1 ADD DATAFILE 'space1f1.ibd'"
	sql_old="$sql_old ; CREATE TABLE t1 (i int) TABLESPACE space1"
	sql_new="SHOW CREATE TABLE t1"
  ;;
  "3")
	echo "-----------------------------------------------"
	echo "Test $testnum: Migration of several tablespaces with several tables"
	echo "-----------------------------------------------"
	sql_old="CREATE TABLESPACE space1 ADD DATAFILE 'space1f1.ibd'"
	sql_old="$sql_old ; CREATE TABLE t1 (i int) TABLESPACE space1"
	sql_old="$sql_old ; INSERT INTO t1 VALUES (1),(2)"
	sql_old="$sql_old ; CREATE TABLE t2 (i int) ROW_FORMAT=COMPACT TABLESPACE space1"
	sql_old="$sql_old ; INSERT INTO t2 VALUES (1),(2)"
	sql_old="$sql_old ; CREATE TABLE t3 (i int) PACK_KEYS=1 TABLESPACE space1"
	sql_old="$sql_old ; INSERT INTO t3 VALUES (1),(2)"
	sql_old="$sql_old ; CREATE TABLESPACE space2 ADD DATAFILE 'space2f1.ibd' FILE_BLOCK_SIZE=8192"
	sql_old="$sql_old ; CREATE TABLE t4 (i int) ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8 TABLESPACE space2"
	sql_old="$sql_old ; INSERT INTO t4 VALUES (1),(2)"
	sql_old="$sql_old ; CREATE TABLE t5 (i int) TABLESPACE space2 KEY_BLOCK_SIZE=8"
	sql_old="$sql_old ; INSERT INTO t5 VALUES (1),(2)"
	sql_old="$sql_old ; CREATE TABLE tsimple (i int)"
	sql_old="$sql_old ; INSERT INTO tsimple VALUES (1),(2)"
	sql_new="SHOW CREATE TABLE t1"
	sql_new="$sql_new ; SHOW CREATE TABLE t2"
	sql_new="$sql_new ; SHOW CREATE TABLE t3"
	sql_new="$sql_new ; SHOW CREATE TABLE t4"
	sql_new="$sql_new ; SHOW CREATE TABLE t5"
	sql_new="$sql_new ; SHOW CREATE TABLE tsimple"
  ;;
  *)
	echo "Unknown test $testnum"
	exit 1
  ;;
esac

set -x

killall mysqld
cd $old_server
rm -rf data
cp -r $old_server_cleandir ./data
start_server > /dev/null
$ml -e "$sql_old" --force
$ml -e "set global innodb_fast_shutdown=0; shutdown"
sleep 3

cd $new_server
rm -rf data
cp -r $old_server/data ./data
start_server > /dev/null
$mupgrade -uroot --protocol=tcp > data/upgrade.log 2>&1
if [ "$?" != 0 ] ; then
  echo "ERROR: mysql_upgrade failed:"
  cat data/upgrade.log
  exit 1
fi
$ml -e shutdown
sleep 3
mv data/log.err data/log.err.old
start_server > /dev/null
$ml -e "$sql_new" --force
$ml -e shutdown
sleep 3
! grep -iE 'warning|error' data/log.err
