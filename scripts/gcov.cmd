VARDIR_HOME=/ssd/logs

set -x
set +e
#perl ./mtr --parallel=1 --vardir=$VARDIR_HOME/var-gcov-vault --force --max-test-fail=0 --big --suite=vault
#perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-sp --force --max-test-fail=0 --big --sp-protocol
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-nm --force --max-test-fail=0 --big 
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-ps --force --max-test-fail=0 --big --ps-protocol
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-view --force --max-test-fail=0 --big --view-protocol --suite=main
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-cursor --force --max-test-fail=0 --big --cursor-protocol
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-emb --force --max-test-fail=0 --big --embedded
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-ps-emb --force --max-test-fail=0 --big --ps-protocol --embedded
perl ./mtr --parallel=8 --vardir=$VARDIR_HOME/var-gcov-extras --force --max-test-fail=0 --big --suite=rocksdb,rocksdb_rpl,s3,spider,spider/bg,engines/funcs,engines/iuds,funcs_1,funcs_2,stress,jp
perl ./mtr --parallel=4 --vardir=$VARDIR_HOME/var-gcov-galera --force --max-test-fail=0 --big --suite=galera,galera_3nodes,wsrep,galera_sr,galera_3nodes_sr
set +x
