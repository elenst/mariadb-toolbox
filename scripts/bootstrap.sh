script_path=`readlink -f $0`
script_home=`dirname $script_path`

. $script_home/test_env $*

rm -rf $tmpdir $datadir 
mkdir $datadir

mysql_install_db=`find $basedir/ -name mysql_install_db | head -1`

# Serve both binary and source builds
if [ -e $basedir/bin/mysqld ] 
then
    dir_param="--basedir=$basedir"
else
    dir_param="--srcdir=$basedir"
fi
if [ -e $basedir/lib/plugin ] ; then
  plugin_dir="--plugin-dir=$basedir/lib/plugin"
fi

cmd="$mysql_install_db $defaults $plugin_dir $dir_param --datadir=$datadir $opts"
echo Bootstrap command line: 
echo $cmd
$cmd

if [ $? -eq 0 ]
then 
	mkdir -p $tmpdir
	echo "Datadir created"
else
	echo "-----------------------------------------------------"
	echo "ERROR: Failed to bootstrap, see logs for more details"
	echo "-----------------------------------------------------"
fi


