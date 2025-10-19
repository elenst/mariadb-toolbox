rm -rf lib/plugin
mkdir -p lib/plugin
for lib in `ls libmariadb/*.so plugin/*/*.so sql/*.so storage/*/*.so`
do
	path=`pwd`"/"$lib
	link=`basename $lib`
	rm -f lib/plugin/$link
	ln -s $path lib/plugin/$link
done
for lib in `ls libmariadb/libmariadb/*.so libmariadb/libmariadb/*.so.*`
do
	path=`pwd`"/"$lib
	link=`basename $lib`
	rm -f lib/$link
	ln -s $path lib/$link
done
if [ -e extra/mariabackup/mariabackup ] && [ ! -e bin/mariabackup ] ; then
  mkdir -p bin
  ln -s `pwd`/extra/mariabackup/mariabackup bin/mariabackup
  ln -s `pwd`/extra/perror bin/perror
fi
for s in wsrep_sst_backup wsrep_sst_mariabackup wsrep_sst_rsync wsrep_sst_common wsrep_sst_mysqldump wsrep_sst_rsync_wan ; do
  if [ -e scripts/$s ] && [ ! -e bin/$s ] ; then
    mkdir -p bin
    ln -s `pwd`/scripts/$s bin/$s
  fi
done
if [ -e plugin/auth_pam/auth_pam_tool ] ; then
  mkdir -p lib/plugin/auth_pam_tool_dir
  ln -s `pwd`/plugin/auth_pam/auth_pam_tool lib/plugin/auth_pam_tool_dir/auth_pam_tool
fi
