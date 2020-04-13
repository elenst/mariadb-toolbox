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
       --test-types=<Types of MTR test runs. Available variants: valgrind, big, sp, view, cursor>
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
        # MDEV-11673 - valgrind errors on binlog_encryption tests
        # MDEV-11686 - valgrind errors on encryption tests
        mtr_options="--valgrind --skip-test=binlog_encryption|encryption"
    ;;
    big)
        build_type=deb
        mtr_options="--big --big --testcase-timeout=2700"
    ;;
    sp|view|cursor)
        build_type=deb
        mtr_options="--${test_type}-protocol"
    ;;
esac

`dirname $0`/rebuild_servers.sh --srchome=$srchome --bldhome=$bldhome --remote-repo=$remote_repo --branches=$branch --builds=$build_type

if [ $? -ne 0 ] ; then
  echo "ERROR: Build failed, tests won't be run"
  exit 1
fi

cd $srchome/$branch
revno=`git log -1 --abbrev=8 --pretty="%h"`
test_id=${branch}_${revno}_${test_type}

if [ -e $logdir/var_${test_id}/log/stdout.log ] ; then
  echo "File $logdir/var_${test_id}/log/stdout.log already exists"
  if grep -E 'Completed:|Too many failed:' $logdir/var_${test_id}/log/stdout.log ; then
    echo "Tests on branch $branch revision $revno already ran"
    if grep 'tests were successful' $logdir/var_${test_id}/log/stdout.log ; then
        echo "The previous run succeeded, it won't hurt to try again"
    else
        exit 1
    fi
  else
    echo "stdout file seems to be incomplete, re-running the tests"
  fi
fi

cd $bldhome/$branch-$build_type/mysql-test
perl ./mysql-test-run.pl $mtr_options --force --max-test-fail=0 --verbose-restart --parallel=48 --vardir=$logdir/var_${branch}_${revno}_${test_type}
res=$?

#cp $logdir/var_${test_id}/log/stdout.log $logdir/stdout_${test_id}

ci=Local-`hostname`
if [ $res -eq 0 ] ; then
  test_result=OK
else
  test_result=FAIL
fi

if [ $test_result == "FAIL" ] ; then
    # extract_failures_from_mtr_stdout prints
    # "test_name" "jira" "strong" for every test/jira match,
    # or
    # "test_name" "" "no_match" for unrecognized failures
    perl `dirname $0`/../scripts/extract_failures_from_mtr_stdout.pl $logdir/var_${test_id}/log/stdout.log > $logdir/failures_${test_id}
    if [ -s $logdir/failures_${test_id} ] ; then
        sed -i -e "s/^/\"$ci\" \"$test_result\" \"$branch\" \"$revno\" \"mtr-$test_type\" /" $logdir/failures_${test_id}
        echo "Loading failures in the database"
        cat $logdir/failures_${test_id}
        $bldhome/$branch-$build_type/bin/mysql --host=$DB_HOST --port=$DB_PORT -u$DB_USER -p$DBP -e "LOAD DATA LOCAL INFILE '$logdir/failures_${test_id}' INTO TABLE regression.result FIELDS TERMINATED BY ' ' ENCLOSED BY '\"' (ci, test_result, server_branch, server_rev, test_info, test_id, jira, notes, match_type)"

    fi
fi

#$bldhome/$branch-$build_type/bin/mysql --host=$DB_HOST --port=$DB_PORT -u$DB_USER -p$DBP -e "INSERT INTO regression.result (ci, test_id, match_type, test_result, url, server_branch, test_info) VALUES ('$ci','$test_id', 'no_match', '$test_result', NULL, '$branch', 'mtr-$test_type')"

exit $res
