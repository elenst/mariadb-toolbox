#!/bin/bash

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//' | sed -e 's/,/ /g'
}

usage()
{
    cat <<EOF
Usage:
    $0
       --vardir=<RQG vardir> (can be provided multiple times)
       --test-log=<RQG output> (can be provided multiple times)
       --help (print this help and exit)
EOF
}

vardir=''
test_log=''
script_location=`dirname $0`

for arg in $* ; do
    case "$arg" in
        --vardir=*) vardir="$vardir "`parse_arg "$arg"` ;;
        --test-log=*|--test_log=*) test_log="$test_log "`parse_arg "$arg"` ;;
        --help) usage && exit 0 ;;
        *) echo "Unknown argument: $arg" && exit 1 ;;
    esac
done

# We want to collect (listed in no particular order):
# - if there are any coredumps inside the vardir(s), then
#   main stack (only) from each coredump;
# - if there are any mysql.err logs in the vardir(s), then
#   all ERROR records from it;
# - if there are any mbackup_* logs in the vardir(s), then
#   all error (case-insensitive) records from it;
# - all error (case-insensitive) records from test output, except for
#   errorfilter output;
# - if there are any *.cnf files in the vardir(s), then
#   the contents of each cnf file;
# - Final command line and server options from each test output;
# - assertion|signal|\[FATAL\]|pure virtual method called records
#   from each mysql.err* and mbackup_* logs;
# - stack traces from each mysql.err* and mbackup_* logs;

# It looks like the collection somehow interferes with server's own postmortem,
# so we'll wait a bit, there is no hurry
sleep 15

for t in $test_log ; do
    echo ""
    echo "----- Test log $t -----"
    grep 'RQG git revision' $t
    echo ""
    grep -E -A 1 'Final command line|Final options' $t | sed -e 's/^.*\] perl /perl /'
    echo ""
    grep -E '^#.*\[ERROR\]|^#.*\[FATAL ERROR\]|DATABASE_CORRUPTION|runall.*exited with exit status|runall.*will exit with exit status|MemoryUsage monitor|FeatureUsage detected' $t
    echo ""
    echo ""
    if grep "TRANSFORM ISSUE" $t > /dev/null ; then
      echo "TRANSFORMATION ISSUES:"
      # Transformation failed
      grep -A 1 'TRANSFORM ISSUE' $t | grep 'Transform GenTest' | sed -e 's/.*\(Transform GenTest.*\)/\1/g' | sort | uniq -c
      # Mismatch with the original query
      grep -A 1 'TRANSFORM ISSUE' $t | grep 'Original query' | sed -e 's/.*\(failed transformation with.*\)/\1/g' | sort | uniq -c
      echo "END OF TRANSFORMATION ISSUES"
    fi
    echo ""
    echo "Query result summary:"
    perl $script_location/rqg_statuses_summary.pl $t
    echo "---------------------------------------------------------"
done

for v in $vardir ; do
    echo ""
    echo "----- Vardir $v -----"
    echo ""

    error_logs=`find $v -name mysql.err*`
    for l in $error_logs ; do
        echo "--- Error log $l"
        echo ""
        echo "Throttled errors:"
        echo "Invalid roles_mapping table entry user : " `grep -c "Invalid roles_mapping table entry user" $l`
        echo "Can't open and lock privilege tables : " `grep -c "Can't open and lock privilege tables" $l`
        echo ""
        grep -Ei '^Version: |assertion|signal |\[FATAL\]|ERROR|pure virtual method|safe_mutex:|overflow|overrun|0x|^Status: |Forcing close of thread|Warning: Memory not freed|Warning.*Thread.*did not exit|InnoDB: A long semaphore wait|WSREP: Server paused at|free\(\): invalid size|InnoDB: Table .* contains .* user defined columns in InnoDB, but .* columns in MariaDB|InnoDB: Using a partial-field key prefix in search' $l | grep -v "Invalid roles_mapping table entry user" | grep -v "Can't open and lock privilege tables"
        echo "---------------------------------------------------------"
        echo ""
    done

    boot_logs=`find $v -name boot.log*`
    for b in $boot_logs ; do
        echo "--- Boot log $b"
        echo ""
        grep -Ei 'assertion|signal |\[FATAL\]|ERROR|pure virtual method|overflow|overrun|0x' $b
        echo "---------------------------------------------------------"
        echo ""
    done

    backup_logs=`find $v -name mbackup_*.log`
    for b in $backup_logs ; do
        echo "--- Backup log $b"
        echo ""
        grep -Ei 'assertion|signal |\[FATAL\]|ERROR|pure virtual method|overflow|overrun|failed|0x' | grep -v 'Copying .*statements_with_errors_or_warnings.frm' $b
        echo "---------------------------------------------------------"
        echo ""
    done

    coredumps=`find $v \( -name core -o -name core.* \)`
    for c in $coredumps ; do
        echo "--- Stack from coredump $c"
        echo ""
        file $c
        binary=`file $c | sed -e "s/.*, from '\([^ ']*\).*/\\1/"`
        if ! gdb --batch --eval-command="thread apply all bt" $binary $c | perl -e '$result=1; while (<>) { if (/\<signal handler called\>/) { $result= 0; last } }; if ($result == 0) { print; while(<>) { last if /^\s*$/; print } }; exit $result' ; then
            echo "Failed to find the signal"
            gdb --batch --eval-command="bt" $binary $c
        fi
        echo ""
    done

    configs=`find $v -maxdepth 1 -name "*.cnf"`
    for c in $configs ; do
        echo "--- Config file $c"
        echo ""
        cat $c
        echo "---------------------------------------------------------"
        echo ""
    done

done
