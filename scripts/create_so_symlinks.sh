rm -rf lib/plugin
mkdir -p lib/plugin
for lib in `ls plugin/*/*.so sql/*.so storage/*/*.so`
do
	path=`pwd`"/"$lib
	link=`basename $lib`
	ln -s $path lib/plugin/$link
done
if [ ! -e bin/mariabackup ] ; then
  mkdir -p bin
  ln -s `pwd`/extra/mariabackup/mariabackup bin/mariabackup
fi
