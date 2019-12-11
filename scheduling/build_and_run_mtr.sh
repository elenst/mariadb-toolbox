#!/bin/bash

echo
date
echo

curdir=`pwd`

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//' | sed -e 's/,/ /g'
}

usage()
{
    cat <<EOF
Usage:
    $0
       --bldhome=<common location for per-branch builds>
       --srchome=<common location of per-branch sources>
       --remote-repo=<location of the repo to clone/pull from>
       --branch=<branch to build and run tests on>
       --test-types=<Types of MTR test runs. Available variants: valgrind, big>
       --logdir=<common location for MTR logs>
       --help (print this help and exit)
EOF
}

for arg in $* ; do
    case "$arg" in
        --bin-home=*|--binhome=*|--bldhome=*|--bld-home=*) bldhome=`parse_arg "$arg"` ;;
        --source-home=*|--sourcehome=*|--src-home=*|--srchome=*) srchome=`parse_arg "$arg"` ;;
        --remote-source=*|--remote-repo=*) remote_repo=`parse_arg "$arg"` ;;
        --branch=*) branch=`parse_arg "$arg"` ;;
        --test-type=*|--test=*) test_type=`parse_arg "$arg"` ;;
        --log-dir=*|--logdir=*) logdir=`parse_arg "$arg"` ;;
        --help) usage && exit 0 ;;
        *) echo "Unknown argument: $arg" && exit 1 ;;
    esac
done

if [ -z "$test_type" ] ; then
    usage
    echo "ERROR: Test type (--test-type) not defined"
    exit 1
fi

if [ -z "$branch" ] ; then
    usage
    echo "ERROR: Server branch not defined"
    exit 1
fi

case $test_type in
    valgrind)
        build_type=valgrind
        mtr_options="--valgrind"
    ;;
    big)
        build_type=deb
        mtr_options="--big --big"
    ;;
esac

`dirname $0`/rebuild_servers.sh --srchome=$srchome --bldhome=$bldhome --remote-repo=$remote_repo --branches=$branch --builds=$build_type

if [ $? -ne 0 ] ; then
  echo "ERROR: Build failed, tests won't be run"
  exit 1
fi

cd $srchome/$branch
revno=`git log -1 --abbrev=8 --pretty="%h"`

if [ -e $logdir/stdout_${branch}_${revno}_${test_type} ] ; then
  if grep 'Completed:' $logdir/stdout_${branch}_${revno}_${test_type} ; then
    echo "Tests on branch $branch revision $revno already ran"
    if grep 'tests were successful' $logdir/stdout_${branch}_${revno}_${test_type} ; then
        exit 0
    else
        exit 1
    fi
  fi
fi

cd $bldhome/$branch-$build_type/mysql-test
perl ./mysql-test-run.pl $mtr_options --force --max-test-fail=10 --verbose-restart --parallel=8 --vardir=$logdir/var_${branch}_${revno}_${test_type}
res=$?

cp $logdir/var_${branch}_${revno}_${test_type}/log/stdout.log $logdir/stdout_${branch}_${revno}_${test_type}
exit $res
