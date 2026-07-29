#!/usr/bin/bash

#set -x

versions="10.6 10.11 11.4 11.8 12.0 12.1 12.2 12.3 main"
lts_versions="10.6 10.11 11.4 11.8 12.3 main"
build_types="asan-ubsan rel"
testcase=""
search_pattern=""
options=""

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//'
}

for arg ; do
  case "$arg" in
    --version=*|--versions=*)       versions=`parse_arg "$arg"` ;;
    --build-type=*|--build-types=*) build_types=`parse_arg "$arg"` ;;
    --test=*|--testcase=*)          testcase=`parse_arg "$arg"` ;;
    --output=*)                     search_pattern=`parse_arg "$arg"` ;;
    --options=*)                    opts=`parse_arg "$arg"` ; options="$options $opts" ;;
    *)                              options="$options $arg" ;;
  esac
done

if [ -z "$testcase" ] ; then
  echo "ERROR: Testcase (--test=X) must be defined"
  exit 1
fi

if [ "$versions" == "lts" ] ; then
  versions=$lts_versions
fi

passed=''
reproducible=''
failed_differently=''
not_found=''

testname=`basename $testcase`
testname=`echo $testname | sed -e 's/\.test$//'`
testdir=`dirname $testcase`
outfile=/data/tmp/versions.out
rm -f $outfile
vardir_prefix=/ssd/logs/versions

for v in $versions ; do
  for build_type in $build_types ; do
    echo "Trying ${v} ${build_type}"
    if [ -d /data/bld/${v}-${build_type}/mysql-test ] ; then
      cd /data/bld/${v}-${build_type}/mysql-test
    elif [ -d /data/bld/${v}-${build_type}/mariadb-test ] ; then
      cd /data/bld/${v}-${build_type}/mariadb-test
    else
      echo "  build or MTR not found!"
      not_found="$not_found ${v}-${build_type}"
      continue
    fi
    vardir="${vardir_prefix}/${v}-${build_type}"
    ./mtr $testname $options --vardir=$vardir >> $outfile 2>&1
    res=$?
    if [ -n "$search_pattern" ] ; then
      if grep -E "$search_pattern" $vardir/log/mysqld.*.err $vardir/log/stdout.log > /dev/null 2>&1 ; then
        reproducible="$reproducible ${v}-${build_type}"
        echo "  MATCHES THE PATTERN"
      elif [ "$res" != "0" ] ; then
        failed_differently="$failed_differently ${v}-${build_type}"
        echo "  FAILED, does not match the pattern"
      else
        passed="$passed ${v}-${build_type}"
        echo "  PASSED, does not match the pattern"
      fi
    else
      if [ "$res" != "0" ] ; then
        reproducible="$reproducible ${v}-${build_type}"
        echo "  FAILED"
      else
        passed="$passed ${v}-${build_type}"
        echo "  PASSED"
      fi
    fi
  done
done

echo "" >> $outfile
echo "Not found builds:" >> $outfile
echo $not_found >> $outfile
echo "Reproducible on:" >> $outfile
echo $reproducible >> $outfile
echo "Failed differently on:" >> $outfile
echo $failed_differently >> $outfile
echo "Not reproducible on:" >> $outfile
echo $passed >> $outfile
tail -n 9 $outfile
echo ""
echo "See logs in $vardir_prefix, output in $outfile"
