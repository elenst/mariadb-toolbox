script_path=`readlink -f $0`
script_home=`dirname $script_path`

. $script_home/test_env $*

cat $basedir/scripts/mysql_system_tables.sql > /tmp/init.sql
cat $basedir/scripts/mysql_performance_tables.sql >> /tmp/init.sql
cat $basedir/scripts/mysql_system_tables_data.sql >> /tmp/init.sql
cmd="$basedir/sql/mysqld --no-defaults --basedir=$basedir --datadir=$datadir --log-error=$datadir/bootstrap.err --bootstrap --loose-lc-messages-dir=$langdir --loose-language=$engdir $opts"
echo Server command line: 
echo $cmd

echo "rm -rf $tmpdir $datadir && mkdir $datadir && mkdir $tmpdir && mkdir $datadir/test && mkdir $datadir/mysql && { echo \"use mysql;\"; cat /tmp/init.sql ; } | $cmd"
rm -rf $tmpdir $datadir && mkdir $datadir && mkdir $tmpdir && mkdir $datadir/test && mkdir $datadir/mysql && { echo "use mysql;"; cat /tmp/init.sql ; } | $cmd

echo Result code: $?
rm /tmp/init.sql

