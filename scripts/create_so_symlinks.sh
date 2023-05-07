rm -rf lib/plugin
mkdir -p lib/plugin
for lib in `ls plugin/*/*.so sql/*.so storage/*/*.so`
do
	path=`pwd`"/"$lib
	link=`basename $lib`
	ln -s $path lib/plugin/$link
done
if [ -e extra/mariabackup/mariabackup ] && [ ! -e bin/mariabackup ] ; then
  mkdir -p bin
  ln -s `pwd`/extra/mariabackup/mariabackup bin/mariabackup
fi
for s in wsrep_sst_backup wsrep_sst_mariabackup wsrep_sst_rsync wsrep_sst_common wsrep_sst_mysqldump wsrep_sst_rsync_wan ; do
  if [ -e scripts/$s ] && [ ! -e bin/$s ] ; then
    mkdir -p bin
    ln -s `pwd`/scripts/$s bin/$s
  fi
done
