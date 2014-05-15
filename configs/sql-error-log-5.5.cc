
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=4
		--duration=600
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld=--performance_schema=1
		--views
		--mysqld=--plugin-load=sql_errlog.so
		--mysqld=--plugin-dir=/home/elenst/maria-5.5/lib/plugin
		--rpl_mode=mixed
	'], 
	[
		'--grammar=conf/runtime/metadata_stability.yy --gendata=conf/runtime/metadata_stability.zz',
		'--grammar=conf/runtime/performance_schema.yy',
		'--grammar=conf/runtime/information_schema.yy',
		'--grammar=conf/engines/many_indexes.yy --gendata=conf/engines/many_indexes.zz',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/partitioning/partitions.yy',
		'--grammar=conf/replication/replication.yy'
	], 
	[
		'',
		'--mysqld=--sql_error_log_rate=10'
	],
	[
		'--mysqld=--sql_error_log_rotate=ON',
		''
	],
	[
		'--mysqld=--sql_error_log_size_limit=1000',
		''
	],
	[
		'--mysqld=--sql_error_log_rotations=1',
		''
	]
];
