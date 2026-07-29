set +e
perl ./mtr --mem --parallel=12 --force --max-test-fail=0 --big
cp var/log/stdout.log ./stdout.nm.log
perl ./mtr --mem --parallel=12 --force --max-test-fail=0 --big --ps-protocol
cp var/log/stdout.log ./stdout.ps.log
perl ./mtr --mem --parallel=12 --force --max-test-fail=0 --big --view-protocol
cp var/log/stdout.log ./stdout.view.log
perl ./mtr --mem --parallel=4 --force --max-test-fail=0 --big --suite=s3
cp var/log/stdout.log ./stdout.s3.log
perl ./mtr --mem --parallel=4 --force --max-test-fail=0 --big --suite=galera,wsrep,galera_3nodes,galera_sr
cp var/log/stdout.log ./stdout.galera.log
perl ./mtr --mem --parallel=4 --force --max-test-fail=0 --big --suite=rocksdb,rocksdb_rpl,rocksdb_sys_vars
cp var/log/stdout.log ./stdout.rocksdb.log

