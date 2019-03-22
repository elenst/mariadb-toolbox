if [ -z "$1" ] ; then
  echo "Usage: $0 <server_branch>"
  $SCRIPT_DIR/soft_exit.sh 1
fi

SERVER_BRANCH=$1
BINTAR_TYPE=${2-"kvm-bintar-trusty-amd64"}

wget -nv -O index1.html http://hasky.askmonty.org/archive/$SERVER_BRANCH/
builds=`grep 'a href="build-' index1.html | sed -e 's/.*href="build-\([0-9]*\).*/\1/g' | sort -r | xargs`

for b in $builds ; do
  wget -nv -O index_$b.html http://hasky.askmonty.org/archive/$SERVER_BRANCH/build-$b/$BINTAR_TYPE/
  if [ -e index_$b.html ] ; then
    tarball=`grep 'a href="mariadb-' index_$b.html | sed -e 's/.*href="\(mariadb-.*\)\.tar\.gz".*/\1/'`
    if [ -n "$tarball" ] ; then
      echo "Found $tarball"
      break
    fi
  fi
done

if [ -n "$tarball" ] ; then

# Before getting the tarball, check if we already had the same
  if [ -e "server/revno" ] ; then
    old_revno=`cat server/revno`
  fi
  wget -nv http://buildbot.askmonty.org/buildbot/builders/kvm-tarbake-jaunty-x86/builds/$b
  new_revno=`grep 'title="Revision' $b | sed -e 's/.*Revision \([0-9a-f]*\)".*/\1/'`
  if [ -n "$old_revno" ] && [ -n "$new_revno" ] && [ "$old_revno" == "$new_revno" ] ; then
    echo "We already have revno $new_revno, skipping the download"
  else
    echo "Old revno: $old_revno , new revno: $new_revno , downloading tarball to replace the server"
    wget -nv http://hasky.askmonty.org/archive/$SERVER_BRANCH/build-$b/$BINTAR_TYPE/$tarball.tar.gz
    rm -rf server
    mkdir server
    cd server
    tar zxf ../$tarball.tar.gz --strip-components=1
    echo $new_revno > revno
    cd ..
  fi
else
  echo "Could not find the server bintar"
  . $SCRIPT_DIR/soft_exit.sh 1
fi
