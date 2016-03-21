
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=32
		--duration=1200
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld=--log_output=FILE
	'], 
	[
		'--grammar=/home/elenst/mariadb-toolbox/rocksdb/stress.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/stress.zz',
		'--grammar=/home/elenst/mariadb-toolbox/rocksdb/stress2.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/stress.zz',
		'--grammar=/home/elenst/mariadb-toolbox/rocksdb/multi_update.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/multi_update.zz',
		'--views --grammar=conf/runtime/metadata_stability.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/metadata_stability.zz',
		'--views --grammar=conf/mariadb/optimizer.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/optimizer.zz',
		'--views --grammar=conf/runtime/information_schema.yy --mysqld=--default-storage-engine=RocksDB',
		'--views --grammar=conf/engines/many_indexes.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/many_indexes.zz',
		'--views --grammar=conf/replication/replication.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/replication-5.1.zz',
		'--grammar=conf/replication/replication-ddl_sql.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/replication-ddl_data.zz',
		'--views --grammar=conf/replication/replication-dml_sql.yy --gendata=/home/elenst/mariadb-toolbox/rocksdb/replication-dml_data.zz',
		'--views --grammar=conf/runtime/connect_kill_sql.yy --gendata=conf/runtime/connect_kill_data.zz --mysqld=--default-storage-engine=RocksDB',
		'--views --grammar=conf/runtime/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz --mysqld=--default-storage-engine=RocksDB'
	],
	[
		'--mysqld=--log-bin --mysqld=--server-id=1',
		''
	]
];

