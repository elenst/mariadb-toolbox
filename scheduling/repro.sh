#!/bin/bash

echo
date
echo

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//' | sed -e 's/,/ /g'
}

usage()
{
    cat <<EOF
Usage:
    $0
       --archdir=<common location for archives>
       --logdir=<common location for logs>
       --output=<search pattern>
       --scriptdir=<script location>
       --test-id=<test ID>
       --help (print this help and exit)
EOF
}

for arg in $* ; do
    case "$arg" in
        --archive-dir=*|--archdir=*|--archives=*) archdir=`parse_arg "$arg"` ;;
        --log-dir=*|--logdir=*) logdir=`parse_arg "$arg"` ;;
        --output=*) output=`parse_arg "$arg"` ;;
        --script-dir=*|--scriptdir=*) scriptdir=`parse_arg "$arg"` ;;
        --test-id=*|--testid=*) test_id=`parse_arg "$arg"` ;;
        --help) usage && exit 0 ;;
        *) echo "Unknown argument: $arg" && exit 1 ;;
    esac
done

if [ ! -e $archdir/${test_id}_repro.tar.gz ] ; then
    echo "Repro archive for $test_id not found"
    exit 1
else
    echo "Found archive for $test_id"
fi

screen_id=`echo $STY | awk -F'.' '{print $3}'`
if [ -z "$screen_id" ] ; then
    screen_id=10
fi
let "mtr_thread = 400 + $screen_id"

rm -rf $logdir/repro_${test_id}_${screen_id}
mkdir $logdir/repro_${test_id}_${screen_id}
cd $logdir/repro_${test_id}_${screen_id}
tar zxf $archdir/${test_id}_repro.tar.gz

options="--output=$output --mtr-thread=$mtr_thread --logdir=$logdir"

f=`find . -name mysql.log`
if [ -n "$f" ] ; then
    cp `find . -name mysql.log | head -n 1 | xargs` ./
    cmd="$options --server-log=$logdir/mysql.log"
fi
f=`find . -name my.cnf`
if [ -n "$f" ] ; then
    cp `find . -name my.cnf | head -n 1 | xargs` ./
    cmd="$options --cnf=$logdir/my.cnf"
fi

rqg_cmd=`grep -A 1 "Final command line" ${test_id}_postmortem | sed -e 's/.* perl //'`

echo "Final options: $options $rqg_cmd"
perl $scriptdir/reprobug.pl $options $rqg_cmd
