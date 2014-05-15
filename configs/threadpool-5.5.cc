
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--duration=900
		--queries=100M
		--mysqld=--innodb-lock-wait-timeout=3
		--mysqld=--lock-wait-timeout=5
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld=--log-output=FILE
		--mysqld=--max-connections=1024
	'], 
	[
		'--grammar=conf/runtime/connect_kill_sql.yy --gendata=conf/runtime/connect_kill_data.zz',
		'--grammar=conf/runtime/WL5004_sql.yy --gendata=conf/runtime/WL5004_data.zz',
		'--grammar=conf/replication/replication-dml_sql.yy --gendata=conf/replication/replication-dml_data.zz',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/WL5004_no_flush_lock.yy --gendata=conf/runtime/WL5004_data.zz'
	], 
        [
                '--engine=Aria',
                '--engine=MyISAM',
                '--engine=InnoDB',
		'--engine=MEMORY',
        ],
	[
		'--mysqld=--loose-thread-pool-size=1',
		'--mysqld=--loose-thread-pool-size=4',
		'--mysqld=--loose-thread-pool-size=128'
	],
	[
		'--threads=16',
		'--threads=1',
		'--threads=128',
	],
	[
		'--mysqld=--loose-thread-pool-max-threads=128',
		'--mysqld=--loose-thread-pool-max-threads=1000'
	],
	[
		'--mysqld=--thread-handling=pool-of-threads',
		'--mysqld=--thread-handling=one-thread-per-connection'
	]
];
