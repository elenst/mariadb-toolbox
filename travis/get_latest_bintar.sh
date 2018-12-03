if [ -z "$1" ] ; then
  echo "Usage: $0 <server_branch>"
  $SCRIPT_DIR/soft_exit.sh 1
fi

SERVER_BRANCH=$1

wget -nv -O index1.html http://hasky.askmonty.org/archive/$SERVER_BRANCH/
builds=`grep 'a href="build-' index1.html | sed -e 's/.*href="\(build-[0-9]*\).*/\1/g' | sort -r | xargs`

for b in $builds ; do
  wget -nv -O index_$b.html http://hasky.askmonty.org/archive/$SERVER_BRANCH/$b/kvm-bintar-trusty-amd64/
  if [ -e index_$b.html ] ; then
    tarball=`grep 'a href="mariadb-' index_$b.html | sed -e 's/.*href="\(mariadb-.*64\)\.tar\.gz".*/\1/'`
    if [ -n "$tarball" ] ; then
      echo "Found $tarball"
      break
    fi
  fi
done

if [ -n "$tarball" ] ; then
  wget -nv http://hasky.askmonty.org/archive/$SERVER_BRANCH/$b/kvm-bintar-quantal-amd64/$tarball.tar.gz
  tar zxf $tarball.tar.gz
  rm -rf server
  mv $tarball server
else
  echo "Could not find the server bintar"
  $SCRIPT_DIR/soft_exit.sh 1
fi
