#!/bin/bash

CLANG=19

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//'
}

parse_args()
{
  small_build=no
  embedded=default
  old_code=no
  options=""
  assert_hack=no
  msan_libs=no

  for arg ; do
    case "$arg" in
      --small)      small_build=yes ;;
      --emb*)       embedded=yes ;;
      --noemb*)     embedded=no ;;
      --old)        old_code=yes ;;
      --assert*)    assert_hack=yes ;;
      --msan*)      msan_libs=yes ;;
      *)            options="$options $arg" ;;
    esac
  done
}

rebuild() {
  rev=`git log -1 --format="%h"`
  if head -1 commits | grep $rev ; then
    echo "No changes from the last build in "`pwd`", nothing to rebuild"
    local dr=`pwd`
    skipped="$skipped "`basename $dr`
  else
    git log --topo-order --oneline > commits
    . ./last_build
  fi
}

local_build() {
  cpus=${nCPU:-$(grep -c processor /proc/cpuinfo)}
  parse_args "$@"
  git log --topo-order --oneline > commits
  rm -f last_build
  extra_options="-DPLUGIN_TOKUDB=NO -DPLUGIN_COLUMNSTORE=NO -DPLUGIN_XPAND=NO"
  if [ "$small_build" == "yes" ] ; then
    extra_options="$extra_options \
      -DPLUGIN_ROCKSDB=NO -DPLUGIN_SPHINX=NO -DPLUGIN_SPIDER=NO \
      -DPLUGIN_MROONGA=NO -DPLUGIN_FEDERATEDX=NO -DPLUGIN_CONNECT=NO \
      -DPLUGIN_FEDERATED=NO -DPLUGIN_OQGRAPH=NO -DWITH_EMBEDDED_SERVER=NO \
      -DWITH_MARIABACKUP=OFF -DWITH_UNIT_TESTS=0"
  fi
  if [ "$old_code" == "yes" ] ; then
    extra_options="$extra_options -DPLUGIN_SPHINX=NO -DPLUGIN_MROONGA=NO \
      -DPLUGIN_CONNECT=NO -DPLUGIN_FEDERATED=NO -DPLUGIN_OQGRAPH=NO \
      -DWITH_EMBEDDED_SERVER=NO -DWITH_UNIT_TESTS=0 -DMYSQL_MAINTAINER_MODE=OFF \
      -DCMAKE_CXX_FLAGS=-std=gnu++98 -DMYSQL_MAINTAINER_MODE=OFF \
      -DDISABLE_LIBMYSQLCLIENT_SYMBOL_VERSIONING=TRUE -DWITH_SSL=bundled \
      -DWITH_UNIT_TESTS=OFF -DCONC_WITH_UNITTEST=OFF -DCONC_WITH_SSL=OFF"
  fi
  if [ -e cmake/build_configurations/enterprise.cmake ] ; then
    extra_options="$extra_options \
      -DPLUGIN_MROONGA=NO -DPLUGIN_SPHINX=NO -DPLUGIN_OQGRAPH=NO \
      -DMAX_INDEXES=128 -DWITH_EXTRA_CHARSETS=all"
  fi
  if [ "$embedded" == "yes" ] ; then
    extra_options="$extra_options -DWITH_EMBEDDED_SERVER=YES"
  elif [ -e cmake/build_configurations/enterprise.cmake ] || [ "$embedded" == "no" ]
  then
    extra_options="$extra_options -DWITH_EMBEDDED_SERVER=NO"
  fi
  sed -i -e 's/RLIMIT_NOFILE, 1024, 1024/RLIMIT_NOFILE, 65536, 65536/' \
    mysql-test/lib/My/SafeProcess/safe_process.cc
  sed -i -e 's/int open_files_limit = 1024/int open_files_limit = 65536/' \
    mysql-test/lib/My/SafeProcess/safe_process.cc
  if [ "$assert_hack" == "yes" ] ; then
    patch -p 1 < /data/src/mariadb-toolbox/data/assert_hack.patch
    patch -p 1 < /data/src/mariadb-toolbox/data/assert_hack_legacy.patch || true
  fi
  {
    if [ "$msan_libs" == "yes" ] ; then
      echo "MSAN_LIBS=$HOME/msan-libs"
      echo "MSAN_OPTIONS=track_origins=1"
    fi
    echo "cmake . $extra_options $options"
    echo ""
    echo "make -j${cpus}"
    echo ". /data/src/mariadb-toolbox/scripts/create_so_symlinks.sh"
  } > ./last_build
  . ./last_build
  if [ -d mysql-test/suite ] ; then
    bugd=mysql-test/suite/bug
  elif [ -d mariadb-test/suite ] ; then
    bugd=mariadb-test/suite/bug
  fi
  rm -f $bugd
  ln -s /data/bug $bugd
}

local_debug() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DMYSQL_MAINTAINER_MODE=OFF $*
}

local_asan() {
  local_build \
    -DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF \
    -DCMAKE_C_FLAGS=-fno-omit-frame-pointer \
    -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer \
    -DWITH_SAFEMALLOC=OFF $*
}

local_asan_ubsan() {
  local_build \
    -DCMAKE_C_FLAGS=\"-Og -march=native -mtune=native -fno-omit-frame-pointer\" \
    -DCMAKE_CXX_FLAGS=\"-Og -march=native -mtune=native -fno-omit-frame-pointer\" \
    -DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=YES \
    -DWITH_UBSAN=YES -DMYSQL_MAINTAINER_MODE=OFF -DWITH_SAFEMALLOC=OFF $*
}

local_ubsan() {
  local_build \
    -DCMAKE_C_FLAGS=\"-Og -march=native -mtune=native\" \
    -DCMAKE_CXX_FLAGS=\"-Og -march=native -mtune=native\" \
    -DCMAKE_BUILD_TYPE=Debug -DWITH_UBSAN=YES \
    -DMYSQL_MAINTAINER_MODE=OFF -DWITH_SAFEMALLOC=OFF $*
  }

local_rel_asan() {
  local_build \
    -DCMAKE_C_FLAGS=-fno-omit-frame-pointer \
    -DCMAKE_CXX_FLAGS=-fno-omit-frame-pointer \
    -DBUILD_CONFIG=mysql_release -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF \
  -DWITH_SAFEMALLOC=OFF $*
}

local_rel() {
  if [ -e cmake/build_configurations/enterprise.cmake ] ; then
    local_build -DBUILD_CONFIG=enterprise $*
  else
    local_build -DBUILD_CONFIG=mysql_release $*
  fi
}

local_valgrind() {
  local_build -DCMAKE_BUILD_TYPE=Debug -DWITH_VALGRIND=YES \
  -DWITH_URING=no -DCMAKE_DISABLE_FIND_PACKAGE_URING=1 -DWITH_SSL=bundled $*
}

local_msan() {
  local_build --msan \
    -DCMAKE_C_FLAGS=\'-O2 -Wno-unused-command-line-argument -fdebug-macro\' \
    -DCMAKE_CXX_FLAGS=\'-stdlib=libc++ -O2 -Wno-unused-command-line-argument -fdebug-macro\' \
    -DMYSQL_MAINTAINER_MODE=OFF -DWITH_EMBEDDED_SERVER=OFF \
    -DWITH_UNIT_TESTS=OFF -DCMAKE_BUILD_TYPE=Debug \
    -DWITH_INNODB_{BZIP2,LZ4,LZMA,LZO,SNAPPY}=OFF \
    -DPLUGIN_{ARCHIVE,TOKUDB,MROONGA,OQGRAPH,ROCKSDB,CONNECT,SPIDER}=NO \
    -DWITH_SAFEMALLOC=OFF -DWITH_{ZLIB,SSL,PCRE}=bundled \
    -DHAVE_LIBAIO_H=0 -DCMAKE_DISABLE_FIND_PACKAGE_{URING,LIBAIO}=1 \
    -DWITH_MSAN=ON -DWITH_DBUG_TRACE=OFF \
    -DCMAKE_C_COMPILER=clang-$CLANG -DCMAKE_CXX_COMPILER=clang++-$CLANG \
    -DWITH_MSAN=ON -DCMAKE_BUILD_WITH_INSTALL_RPATH=/tmp/inst
}

local_gcov() {
  local_build \
    -DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=ON --embedded \
    -DCMAKE_C_FLAGS=\"--coverage -fno-inline -fno-inline-small-functions -fno-default-inline -O0\" \
    -DCMAKE_CXX_FLAGS=\"--coverage -fno-inline -fno-inline-small-functions -fno-default-inline -O0\"
  {
    echo "ln -s ./storage/innobase/fts/fts0pars.y fts0pars.y"
    echo "ln -s ./storage/innobase/fts/fts0pars.cc fts0pars.cc"
    echo "ln -s ./storage/innobase/fts/fts0tlex.l fts0tlex.l"
    echo "ln -s ./storage/innobase/fts/fts0tlex.cc fts0tlex.cc"
    echo "ln -s ./storage/innobase/fts/fts0blex.cc fts0blex.cc"
    echo "ln -s ./storage/innobase/fts/fts0blex.l fts0blex.l"
    echo "ln -s ./storage/innobase/pars/pars0lex.l pars0lex.l"
    echo "ln -s ./storage/innobase/pars/lexyy.cc lexyy.cc"
    echo "ln -s ./storage/innobase/pars/pars0grm.cc pars0grm.cc"
    echo "ln -s ./storage/innobase/pars/pars0grm.y pars0grm.y"
    echo "ln -s ./storage/mroonga/vendor/groonga/lib/grn_ecmascript.lemon grn_ecmascript.lemon"
    echo "ln -s ./storage/mroonga/vendor/groonga/lib/grn_ecmascript.c grn_ecmascript.c"
    echo "lcov --directory `pwd` --zerocounters"
    echo "lcov --rc lcov_function_coverage=0 --rc lcov_branch_coverage=1 " \
      "--rc geninfo_gcov_all_blocks=0 --rc geninfo_external=0 --no-external " \
      "-c -i -b `pwd` -d `pwd` -o lcov.baseline --quiet"
  } > last_build_lcov
  . ./last_build_lcov
  cat last_build_lcov >> last_build
  rm ./last_build_lcov
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
  git log --format=fuller --parents --topo-order > log
}

