
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--duration=600
		--queries=100M
		--mysqld=--innodb-lock-wait-timeout=3
		--mysqld=--table-lock-wait-timeout=5
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld=--log-output=FILE
		--engine=Aria
	'], 
	[
		'--grammar=conf/runtime/connect_kill_sql.yy --gendata=conf/runtime/connect_kill_data.zz',
		'--grammar=conf/runtime/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz',
		'--grammar=conf/runtime/information_schema.yy',
		'--grammar=conf/engines/maria/maria_dml_alter.yy',
		'--grammar=conf/engines/maria/maria_stress.yy',
		'--grammar=conf/engines/maria/maria_bulk_insert.yy',
		'--grammar=conf/engines/many_indexes.yy --gendata=conf/engines/many_indexes.zz',
		'--grammar=conf/engines/varchar.yy --gendata=conf/engines/varchar.zz',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/engines/handler.yy --gendata=conf/engines/handler.zz',
		'--grammar=conf/transactions/transactions.yy --gendata=conf/transactions/transactions.zz',
		'--grammar=conf/partitioning/partitions.yy',
		'--grammar=conf/replication/replication.yy'
	], 
	[
		'--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock',
		'--reporters=Backtrace,ErrorLog,Recovery',
		'--reporters=Backtrace,ErrorLog,AriaDoubleRecovery'
	]
];
