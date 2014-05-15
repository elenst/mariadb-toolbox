rm -rf lib/plugin
mkdir -p lib/plugin
for lib in `ls plugin/*/*.so sql/*.so storage/*/*.so`
do
	path=`pwd`"/"$lib
	link=`basename $lib`
	ln -s $path lib/plugin/$link
done

