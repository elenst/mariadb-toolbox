# First argument is the location of RQG (for the tool and signatures)

vardirs=`ls | grep vardir1 | xargs`
rqg=${1-"/data/src/rqg"}

echo "RQG in use: $rqg"

res=0
if ls $rqg/util/bug_signatures* ; then
  signatures=$rqg/util
elif ls $rqg/data/bug_signatures* ; then
  signatures=$rqg/data
else
  echo "ERROR: Signatures not found"
  exit 1
fi
for v in $vardirs ; do
  log=`echo $v | sed -e 's/vardir1_\([0-9]*\)/trial\1.log/'`
  echo "###################################"
  echo "Log: $log"
#  grep -a 'Test run ends with exit status' $log | sed -e 's/^.*Test run ends with exit status/Result:/'
  if ! perl $rqg/util/check_for_known_bugs.pl --signatures=$signatures/bug_signatures* $v/s*/mysql.err $log $v/s*/boot.log ; then
    res=1
  fi
  echo "###################################"
done
(exit $res)
