#!/usr/bin/bash
#
#  Copyright (c) 2017, 2018, MariaDB
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

# The script gets from the environment:
# $HOME (mandatory)
# $BASEDIR (mandatory)
# $GLOBAL_CMAKE_OPTIONS (optional)
# $JOB_CMAKE_OPTIONS (optional)

set -x

if [ -e $BASEDIR/revno ] ; then
  CACHED_REVISION=`cat $BASEDIR/revno`
fi

cd $SRCDIR
export SERVER_REVISION=`git log -1 | head -1 | sed -e 's/^commit \([a-f0-9]*\)/\1/'`

if [ "$SERVER_REVISION" == "$CACHED_REVISION" ] && [ "$RERUN_OLD_SERVER" != "yes" ] && [ -e $BASEDIR/test_result ] ; then
  echo "Test result for revision $SERVER_REVISION has already been cached, re-run is not requested, tests will be skipped."
  echo "For details of the test run, check logs of previous builds. Cached result:"
  cat $BASEDIR/test_result
  $SCRIPT_DIR/soft_exit.sh 0
fi

# In all other cases, we want to rewrite the old result, so we are removing it
rm -f $BASEDIR/test_result

if [ "$SERVER_REVISION" != "$CACHED_REVISION" ] || [ "$REBUILD_OLD_SERVER" == "yes" ] ; then 
  echo "Cached revision $CACHED_REVISION, new revision $SERVER_REVISION, build is required or requested"
  export CMAKE_OPTIONS="$GLOBAL_CMAKE_OPTIONS $JOB_CMAKE_OPTIONS"
  rm -rf $BASEDIR
  mkdir $BASEDIR
  rm -rf $HOME/out-of-source
  mkdir $HOME/out-of-source
  cd $HOME/out-of-source
  cmake $HOME/src $CMAKE_OPTIONS -DCMAKE_INSTALL_PREFIX=$BASEDIR > cmake.out 2>&1
  if [ "$?" != "0" ] ; then
    cat cmake.out
    echo "FATAL ERROR: cmake failed"
    exit 1
  fi
  if ! make -j6 ; then
    echo "FATAL ERROR: make failed"
    exit 1
  fi
  make install > /dev/null
  echo $SERVER_REVISION > $BASEDIR/revno
  echo $CMAKE_OPTIONS > $BASEDIR/cmake_options
  rm -rf $HOME/out-of-source
elif [ -n "$RERUN_OLD_SERVER" ] ; then
  echo "Revision $SERVER_REVISION has already been cached, build is not needed, tests will be re-run as requested"
  if [ -e "$BASEDIR/cmake_options" ] ; then
    CMAKE_OPTIONS=`cat $BASEDIR/cmake_options`
  fi
else
  echo "Revision $SERVER_REVISION has already been cached, build is not needed, but there is no stored test result, so tests will be run"
  if [ -e "$BASEDIR/cmake_options" ] ; then
    CMAKE_OPTIONS=`cat $BASEDIR/cmake_options`
  fi
fi

set +x
