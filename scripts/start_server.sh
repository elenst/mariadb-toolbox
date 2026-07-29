script_path=`readlink -f $0`
script_home=`dirname $script_path`

. $script_home/test_env $*
if [ $result -gt 0 ]
then
	echo "---------------------------------------------"
	echo "ERROR: test_env script finished with an error"
	echo "---------------------------------------------"
	exit 1
fi

if [ -e $basedir/bin/mariadbd ]
then
    mysqld_binary="$basedir/bin/mariadbd"
    mysqladmin_binary="$basedir/bin/mariadb-admin"
elif [ -e $basedir/sql/mariadbd ]
then
    mysqld_binary="$basedir/sql/mariadbd"
    mysqladmin_binary="$basedir/client/mariadb-admin"
elif [ -e $basedir/bin/mysqld ]
then
    mysqld_binary="$basedir/bin/mysqld"
    mysqladmin_binary="$basedir/bin/mysqladmin"
else
    mysqld_binary="$basedir/sql/mysqld"
    mysqladmin_binary="$basedir/client/mysqladmin"
fi

if [ -e $basedir/lib/plugin ] ; then
  plugin_dir="--plugin-dir=$basedir/lib/plugin"
fi

echo "Checking that no server is running on the given port ($port)..."
$mysqladmin_binary --no-defaults --silent -uroot --protocol=tcp --port=$port ping
if [ $? -eq 0 ] 
then
	echo "--------------------------------------------------------------------------------------"
	echo "ERROR: There is a server running on port $port, stop it manually and re-run the script"
	echo "--------------------------------------------------------------------------------------"
	exit 1
fi

rr_or_valgrind=""
if [ -n "$rr" ] ; then
  rr_or_valgrind=$rr
else
  rr_or_valgrind=$valgrind
fi

cmd="$rr_or_valgrind $mysqld_binary $group_suffix $defaults $plugin_dir --basedir=$basedir --datadir=$datadir --log-error=$datadir/log.err --loose-lc-messages-dir=$langdir --loose-language=$engdir --port=$port --socket=$tmpdir/mysql.sock --core-file --tmpdir=$tmpdir $opts"

echo Server command line:
echo $cmd

$cmd &

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
do
	echo ...
	sleep 1
	$mysqladmin_binary --no-defaults --silent --socket=$tmpdir/mysql.sock ping
	res=$?
	if [ $res -eq 0 ] 
	then
		break
	fi
done
if [ $res -gt 0 ] 
then
	echo "----------------------------------------------------------------------"
	echo "ERROR: Could not start the server, check the log file for more details"
	echo "----------------------------------------------------------------------"
	exit 1
fi

