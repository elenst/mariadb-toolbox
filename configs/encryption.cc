
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=8
		--duration=300
		--queries=100M
		--redefine=conf/mariadb/general-workarounds.yy
		--redefine=/home/elenst/mariadb-toolbox/grammars/10.1-encryption-redefine.yy
		--rpl_mode=mixed
		--restart-timeout=30
		--validators=none
		--mysqld=--log_output=FILE
		--mysqld=--log_bin_trust_function_creators=1
		--mysqld=--slave_parallel_threads=8
		--mysqld=--plugin_load_add=file_key_management.so
		--mysqld=--file_key_management_filename=/home/elenst/git/10.1/mysql-test/std_data/keys.txt
		--mysqld=--slave_skip_errors=1049,1305,1539,1505,1317
	'], 
	[
		'--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Restart',
		'--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,CrashRestart'
	],
	[
		'--grammar=conf/runtime/metadata_stability.yy --gendata=conf/runtime/metadata_stability.zz',
		'--grammar=conf/runtime/performance_schema.yy',
		'--grammar=conf/runtime/information_schema.yy',
		'--grammar=conf/engines/many_indexes.yy --gendata=conf/engines/many_indexes.zz',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/partitioning/partitions.yy',
		'--grammar=conf/partitioning/partition_pruning.yy --gendata=conf/partitioning/partition_pruning.zz',
		'--grammar=conf/replication/replication.yy --gendata=conf/replication/replication-5.1.zz',
		'--grammar=conf/replication/replication-ddl_sql.yy --gendata=conf/replication/replication-ddl_data.zz',
		'--grammar=conf/replication/replication-dml_sql.yy --gendata=conf/replication/replication-dml_data.zz',
		'--grammar=conf/runtime/connect_kill_sql.yy --gendata=conf/runtime/connect_kill_data.zz',
		'--grammar=conf/runtime/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz'
	],
	[
		'--engine=InnoDB',
		'--engine=Aria',
		'--engine=InnoDB --mysqld=--ignore_builtin_innodb --mysqld=--plugin_load_add=ha_innodb.so'
	],
	[
		'--mysqld=--innodb_encrypt_log=ON',
		'--mysqld=--innodb_encrypt_log=OFF'
	],
	[
		'--mysqld=--innodb_scrub_log=ON',
		'--mysqld=--innodb_scrub_log=OFF'
	],
	[
		'--mysqld=--innodb_default_encryption_key_id=1',
		'--mysqld=--innodb_default_encryption_key_id=2',
		'--mysqld=--innodb_default_encryption_key_id=6',
	],
	[
		'--mysqld=--encrypt_tmp_disk_tables=1',
		'--mysqld=--encrypt_tmp_disk_tables=0'
	],
	[
		'--mysqld=--encrypt_tmp_files=1',
		'--mysqld=--encrypt_tmp_files=0'
	],
	[
		'--mysqld=--encrypt_binlog=1',
		'--mysqld=--encrypt_binlog=0'
	]
];
	
