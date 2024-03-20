#!/bin/bash

echo "Build start: "`date`

BRANCHES=""
BUILDS=""

failed=""
skipped=""

for arg in $@ ; do
  if [[ $arg =~ ^[0-9][0-9]*.[0-9][0-9]* ]] ; then
    BRANCHES="$BRANCHES $arg"
  else
    BUILDS="$BUILDS $arg"
  fi
done

echo "Builds: $BUILDS"
echo "Branches: $BRANCHES"

rebuild() {
  rev=`git log -1 --format="%h"`
  if head -1 commits | grep $rev ; then
    echo "No changes from the last build in "`pwd`", nothing to rebuild"
    dr=`pwd`
    skipped="$skipped "`basename $dr`
  else
    ./last_build
  fi
}

local_build() {
  if [ -z "$nCPU" ]; then cpus=$(grep -c processor /proc/cpuinfo); else cpus=$nCPU ; fi
  git log --topo-order --oneline > commits
  rm -f last_build
  local extra_options="-DPLUGIN_TOKUDB=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_XPAND=NO"
  if [ -e cmake/build_configurations/enterprise.cmake ] ; then
    local extra_options="$extra_options -DWITH_EMBEDDED_SERVER=NO -DMAX_INDEXES=128 -DWITH_EXTRA_CHARSETS=all"
  else
    local extra_options="$extra_options -DWITH_EMBEDDED_SERVER=YES"
  fi
  sed -i -e 's/RLIMIT_NOFILE, 1024, 1024/RLIMIT_NOFILE, 65536, 65536/'  mysql-test/lib/My/SafeProcess/safe_process.cc
  echo "cmake . $extra_options $*" >> ./last_build
  echo "" >> ./last_build
  echo "make -j${cpus}" >> ./last_build
  echo ". /data/src/mariadb-toolbox/scripts/create_so_symlinks.sh" >> ./last_build
  . ./last_build
  rm -f mysql-test/suite/bug
  ln -s /data/bug mysql-test/suite/bug
}

local_debug() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DMYSQL_MAINTAINER_MODE=OFF $*
}

small_debug() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPHINX=NO -DPLUGIN_SPIDER=NO -DPLUGIN_MROONGA=NO -DPLUGIN_TOKUDB=NO -DPLUGIN_FEDERATEDX=NO -DPLUGIN_CONNECT=NO -DPLUGIN_FEDERATED=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_OQGRAPH=NO -DWITH_EMBEDDED_SERVER=NO -DWITH_MARIABACKUP=OFF -DWITH_UNIT_TESTS=0 $*
}

local_asan() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF -DCMAKE_C_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer -DWITH_SAFEMALLOC=OFF $*
}

small_asan() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPHINX=NO -DPLUGIN_SPIDER=NO -DPLUGIN_MROONGA=NO -DPLUGIN_TOKUDB=NO -DPLUGIN_FEDERATEDX=NO -DPLUGIN_CONNECT=NO -DPLUGIN_FEDERATED=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_OQGRAPH=NO -DWITH_EMBEDDED_SERVER=NO -DWITH_MARIABACKUP=OFF -DWITH_UNIT_TESTS=0 -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF -DCMAKE_C_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer -DWITH_SAFEMALLOC=OFF $*
}

local_ubsan() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DWITH_UBSAN=YES -DMYSQL_MAINTAINER_MODE=OFF "-DCMAKE_C_FLAGS=\"-Og -march=native -mtune=native\"" "-DCMAKE_CXX_FLAGS=\"-Og -march=native -mtune=native\"" -DWITH_SAFEMALLOC=OFF $*
}

local_rel_asan() {
  local_build -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF -DCMAKE_C_FLAGS=-fno-omit-frame-pointer -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer -DWITH_SAFEMALLOC=OFF $*
}

local_rel() {
  local_build -DBUILD_CONFIG=mysql_release $*
}

local_valgrind() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DWITH_VALGRIND=YES -DWITH_URING=no -DCMAKE_DISABLE_FIND_PACKAGE_URING=1 -DWITH_SSL=bundled $*
}

local_msan() {
  git log --topo-order --oneline > commits
  rm -f last_build
  sed -i -e 's/RLIMIT_NOFILE, 1024, 1024/RLIMIT_NOFILE, 65536, 65536/'  mysql-test/lib/My/SafeProcess/safe_process.cc
  echo "MSAN_LIBS=$HOME/msan-libs" >> ./last_build
  if [ -e cmake/build_configurations/enterprise.cmake ] ; then
    local extra_options="-DMAX_INDEXES=128 -DWITH_EXTRA_CHARSETS=all"
  fi
  echo "MSAN_OPTIONS=track_origins=1 cmake -DPLUGIN_ROCKSDB=NO -DPLUGIN_CONNECT=NO -DPLUGIN_EXAMPLE=NO -DPLUGIN_TOKUDB=NO -DPLUGIN_SPIDER=NO -DCMAKE_BUILD_TYPE=Debug -DMYSQL_MAINTAINER_MODE=OFF -DWITH_EMBEDDED_SERVER=NO -DWITH_SAFEMALLOC=OFF -DWITH_ZLIB=bundled -DWITH_SSL=bundled -DWITH_PCRE=bundled -DCMAKE_DISABLE_FIND_PACKAGE_URING=1 -DCMAKE_DISABLE_FIND_PACKAGE_LIBAIO=1 -DHAVE_LIBAIO_H=0 '-DCMAKE_C_FLAGS=-O2 -Wno-unused-command-line-argument -fdebug-macro' '-DCMAKE_CXX_FLAGS=-stdlib=libc++ -O2 -Wno-unused-command-line-argument -fdebug-macro' -DCMAKE_C_COMPILER=clang-11 -DCMAKE_CXX_COMPILER=clang++-11 $extra_options -DWITH_MSAN=ON -DCMAKE_BUILD_WITH_INSTALL_RPATH=/tmp/inst -G Ninja ." >> ./last_build
  echo "MSAN_OPTIONS=track_origins=1 ninja" >> ./last_build
  echo ". /data/src/mariadb-toolbox/scripts/create_so_symlinks.sh" >> ./last_build
  . ./last_build
  rm -f mysql-test/suite/bug
  ln -s /data/bug mysql-test/suite/bug
}

local_gcov() {
  if [ -z "$nCPU" ]; then cpus=$(grep -c processor /proc/cpuinfo); else cpus=$nCPU ; fi
  echo 'cmake . -DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=ON -DCMAKE_C_FLAGS="--coverage -fno-inline -fno-inline-small-functions -fno-default-inline -O0" -DCMAKE_CXX_FLAGS="--coverage -fno-inline -fno-inline-small-functions -fno-default-inline -O0"' > last_build
  echo "make -j${cpus}" >> last_build
  echo ". /data/src/mariadb-toolbox/scripts/create_so_symlinks.sh" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0pars.y fts0pars.y" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0pars.cc fts0pars.cc" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0tlex.l fts0tlex.l" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0tlex.cc fts0tlex.cc" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0blex.cc fts0blex.cc" >> ./last_build
  echo "ln -s ./storage/innobase/fts/fts0blex.l fts0blex.l" >> ./last_build
  echo "ln -s ./storage/innobase/pars/pars0lex.l pars0lex.l" >> ./last_build
  echo "ln -s ./storage/innobase/pars/lexyy.cc lexyy.cc" >> ./last_build
  echo "ln -s ./storage/innobase/pars/pars0grm.cc pars0grm.cc" >> ./last_build
  echo "ln -s ./storage/innobase/pars/pars0grm.y pars0grm.y" >> ./last_build
  echo "ln -s ./storage/mroonga/vendor/groonga/lib/grn_ecmascript.lemon grn_ecmascript.lemon" >> ./last_build
  echo "ln -s ./storage/mroonga/vendor/groonga/lib/grn_ecmascript.c grn_ecmascript.c" >> ./last_build
  echo "lcov --directory `pwd` --zerocounters" >> ./last_build
  echo "lcov --rc lcov_function_coverage=0 --rc lcov_branch_coverage=1 --rc geninfo_gcov_all_blocks=0 --rc geninfo_external=0 --no-external -c -i -b `pwd` -d `pwd` -o lcov.baseline --quiet" >> ./last_build
  . ./last_build
}

refresh_source() {
  ver=$1
  repo=$2
  if [[ $repo =~ Enterprise ]] ; then
    rm -rf /data/src/$ver
  fi
  if ! [ -d /data/src/$ver ] ; then
    cd /data/src/
    git clone $repo --branch $ver $ver
  fi
  cd /data/src/$ver
  git reset --hard HEAD
  git clean -ddffxx
  git submodule foreach --recursive git clean -ddffxx
  git checkout $ver
  git pull
  git submodule init
  git submodule update --recursive || git submodule update --recursive
}

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
