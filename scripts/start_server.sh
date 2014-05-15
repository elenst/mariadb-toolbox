script_path=`readlink -f $0`
script_home=`dirname $script_path`

. $script_home/test_env $*


cmd="$basedir/sql/mysqld --no-defaults --basedir=$basedir --datadir=$datadir --log-error=$datadir/log.err --loose-lc-messages-dir=$langdir --loose-language=$engdir --port=$port --socket=$tmpdir/mysql.sock --tmpdir=$tmpdir --loose-core $opts"

echo Server command line:
echo $cmd

$cmd &

echo Sleeping 5 sec...
sleep 5

echo Pinging...
$basedir/client/mysqladmin --no-defaults -uroot --protocol=tcp --port=$port ping

echo Result: $?

