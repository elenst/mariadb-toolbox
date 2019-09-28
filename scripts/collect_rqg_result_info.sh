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
# - Final command line from each test output;
# - assertion|signal|\[FATAL\]|pure virtual method called records
#   from each mysql.err* and mbackup_* logs;
# - stack traces from each mysql.err* and mbackup_* logs;

# It looks like the collection somehow interferes with server's own postmortem,
# so we'll wait a bit, there is no hurry
sleep 15

for t in $test_log ; do
    echo ""
    echo "----- Test log $t -----"
    echo ""
    grep -A 1 'Final command line' $t | sed -e 's/^.*\] perl /perl /'
    echo ""
    grep -E '^#.*\[ERROR\]|^#.*\[FATAL ERROR\]|DATABASE_CORRUPTION|runall.*exited with exit status|runall.*will exit with exit status' $t
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
        grep -Ei '^Version: |assertion|signal |\[FATAL\]|ERROR|pure virtual method|safe_mutex:|overflow|overrun|0x|^Status: ' $l
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
        grep -Ei 'assertion|signal |\[FATAL\]|ERROR|pure virtual method|overflow|overrun|0x' $b
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
