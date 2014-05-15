
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=4
		--duration=300
		--queries=100M
		--reporters=CrashRecovery,ReplicationConsistency,QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--mysqld=--myisam-recover-options=FORCE 
		--mysqld=--aria-recover=FORCE
		--mysqld=--log-output=FILE
		--mysqld=--general-log=1
	'], 
	[
		'--grammar=conf/runtime/metadata_stability.yy --gendata=conf/runtime/metadata_stability.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/performance_schema.yy',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/information_schema.yy',
		'--grammar=conf/engines/many_indexes.yy --gendata=conf/engines/many_indexes.zz',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/partitioning/partitions.yy',
		'--grammar=conf/partitioning/partition_pruning.yy --gendata=conf/partitioning/partition_pruning.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/replication.yy --gendata=conf/replication/replication-5.1.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/replication-ddl_sql.yy --gendata=conf/replication/replication-ddl_data.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/replication-dml_sql.yy --gendata=conf/replication/replication-dml_data.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/connect_kill_sql.yy --gendata=conf/runtime/connect_kill_data.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev-181-225-232/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz'
	],
	[
		'--engine=InnoDB --mysqld=--innodb_flush_log_at_trx_commit=3',
		'--engine=InnoDB --mysqld=--innodb_flush_log_at_trx_commit=1',
		'--engine=MyISAM',
		'--engine=Aria',
		'--mysqld=--default-storage-engine=memory',
		'--mysqld=--plugin-load=ha_innodb.so --mysqld=--default-storage-engine=innodb'
	],
	[
		'--rpl_mode=row',
		'--rpl_mode=mixed'
	],
	[
		'',
		'--mysqld=--debug_binlog_fsync_sleep=200000'
	],
];

