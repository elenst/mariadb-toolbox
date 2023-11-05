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

set -x

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
    grep -a 'RQG git revision' $t
    echo ""
    grep -aE -A 1 'Final command line|Final options' $t | sed -e 's/^.*\] perl /perl /'
    echo ""
    grep -aE '^#.*\[ERROR\]|^#.*\[FATAL ERROR\]|DATABASE_CORRUPTION|STATUS_OUT_OF_MEMORY|ALARM|ENVIRONMENT|CRITICAL|REPLICATION_FAILURE|runall.*exited with exit status|runall.*will exit with exit status|Test run ends with exit status|MemoryUsage monitor|FeatureUsage detected|^mysqldump|^mariadb-dump|undefined value as an ARRAY reference' $t | grep -vE "Executor::MariaDB::execute: Failed to reconnect after getting|Discarding query"
    echo ""
    echo ""
    if grep -a "TRANSFORM ISSUE" $t > /dev/null ; then
      echo "TRANSFORMATION ISSUES:"
      # Transformation failed
      grep -a -A 1 'TRANSFORM ISSUE' $t | grep -a 'Transform GenTest' | sed -e 's/.*\(Transform GenTest.*\)/\1/g' | sort | uniq -c
      # Mismatch with the original query
      grep -a -A 1 'TRANSFORM ISSUE' $t | grep -a 'Original query' | sed -e 's/.*\(failed transformation with.*\)/\1/g' | sort | uniq -c
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
        echo "Invalid roles_mapping table entry user : " `grep -a -c "Invalid roles_mapping table entry user" $l`
        echo "Can't open and lock privilege tables : " `grep -a -c "Can't open and lock privilege tables" $l`
        echo "WSREP: Ignoring error" `grep -a -c "WSREP: Ignoring error" $l`
        echo ""
        grep -Eai '^Version: |assertion|signal |\[FATAL\]|ERROR|pure virtual method|safe_mutex:|overflow|overrun|0x|^Status: |Forcing close of thread|Warning: Memory not freed|Warning.*Thread.*did not exit|InnoDB: A long semaphore wait|WSREP: Server paused at|free\(\): invalid size|InnoDB: Table .* contains .* user defined columns in InnoDB, but .* columns in MariaDB|InnoDB: Using a partial-field key prefix in search|Normal shutdown|Shutdown complete|InnoDB: Starting shutdown|InnoDB: Shutdown completed|debugger aborting' $l | \
        grep -Eav "Can't open and lock privilege tables|Invalid roles_mapping table entry user|Deadlock found when trying to get lock; try restarting transaction|Lock wait timeout exceeded; try restarting transaction|Aborted connection|has or is referenced in foreign key constraints which are not compatible|Foreign Key referenced table .* not found for foreign table|Cannot add field .* because after adding it, the row size is .* which is greater than maximum allowed size|\[ERROR\] Event Scheduler: \[.*\@localhost\]\.*\[.*\] |WSREP: Ignoring error"
        echo "---------------------------------------------------------"
        echo ""
    done

    boot_logs=`find $v -name boot.log*`
    for b in $boot_logs ; do
        echo "--- Boot log $b"
        echo ""
        grep -Eai 'assertion|signal |\[FATAL\]|ERROR|pure virtual method|overflow|overrun|0x' $b
        echo "---------------------------------------------------------"
        echo ""
    done

    backup_logs=`find $v -name mbackup_*.log`
    for b in $backup_logs ; do
        echo "--- Backup log $b"
        echo ""
        grep -Eai 'assertion|signal |\[FATAL\]|ERROR|pure virtual method|overflow|overrun|failed|0x' $b | grep -va 'Copying .*statements_with_errors_or_warnings.frm'
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
