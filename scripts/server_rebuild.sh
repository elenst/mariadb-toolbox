#!/bin/bash

. /usr/local/bin/server_build_functions

echo "Build start: "`date`

BRANCHES=""
BUILDS=""

failed=""
skipped=""

for arg in $@ ; do
  if [[ $arg =~ ^[0-9][0-9]*.[0-9][0-9]* ]] || [ "$arg" == "main" ] ; then
    BRANCHES="$BRANCHES $arg"
  else
    BUILDS="$BUILDS $arg"
  fi
done

echo "Builds: $BUILDS"
echo "Branches: $BRANCHES"

for v in $BRANCHES ; do
  if [[ $v =~ "enterprise" ]] ; then
    repo="git@github.com:mariadb-corporation/MariaDBEnterprise.git"
  else
    repo="https://github.com/MariaDB/server"
  fi
  refresh_source $v $repo
  for b in $BUILDS ; do
    echo
    echo "Build: ${v}-${b}"
    echo
    cd /data/bld
    if [ $v == "10.4" ] && ( [ "$b" == "msan" ] || [ "$b" == "ubsan" ] ) ; then
      continue
    fi
    blddir=${v}-${b}
    if [ -e $blddir/last_build ] && [ -e $blddir/sql/mariadbd ] ; then
      cd $blddir
      git checkout $v
      git pull
      git submodule update --recursive || git submodule update --recursive
      rebuild
    else
      rm -rf $blddir
      git clone /data/src/$v $blddir
      cd $blddir
      case $b in
        asan)
          local_asan
          ;;
        debug)
          local_debug
          ;;
        ubsan)
          local_ubsan
          ;;
        msan)
          local_msan
          ;;
        rel)
          local_rel
          ;;
        rel-asan)
          local_rel_asan
          ;;
        valgrind)
          local_valgrind
          ;;
        gcov)
          local_gcov
          ;;
        *)
          echo "ERROR: Unknown build type $b"
          failed="$failed $v-$b"
          ;;
      esac
      if [ "$?" != "0" ] ; then
        failed="$failed $v-$b"
      fi
    fi
  done
done

if [ -n "$skipped" ] ; then
  echo "Skipped builds: $skipped"
fi
if [ -n "$failed" ] ; then
  echo "Failed builds: $failed"
else
  echo "All builds succeeded (or skipped)"
fi

echo "Build end: "`date`
