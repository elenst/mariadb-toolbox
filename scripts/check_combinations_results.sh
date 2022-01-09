# First argument is the location of RQG (for the tool and signatures)

vardirs=`ls | grep vardir1 | xargs`
rqg=${1-"/data/src/rqg"}

for v in $vardirs ; do
  log=`echo $v | sed -e 's/vardir1_\([0-9]*\)/trial\1.log/'`
  echo "###################################"
  echo "Log: $log"
  grep 'runall-new.pl will exit with exit status' $log | sed -e 's/^.*runall-new.pl will exit with exit status/Result:/'
#  set -x
  perl $rqg/util/check_for_known_bugs.pl --signatures=$rqg/data/bug_signatures $v/mysql.err $log
#  set +x
  echo "###################################"
done