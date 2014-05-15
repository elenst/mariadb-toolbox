
$combinations = [
	[
	'
		--debug
		--no-mask
		--seed=time
		--threads=4
		--duration=900
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--validators=ErrorMessageCorruption
		--mysqld=--performance_schema=1
		--views
		--mysqld=--slave-skip-errors=all
	'], 
	[
		'--grammar=/home/elenst/mariadb-toolbox/grammars/skip-replication-5.5.yy --gendata=conf/replication/replication-5.1.zz'
	], 
	[
		'--mysqld=--replicate-events-marked-for-skip=REPLICATE',
		'--mysqld=--replicate-events-marked-for-skip=FILTER_ON_SLAVE',
		'--mysqld=--replicate-events-marked-for-skip=FILTER_ON_MASTER',
		'--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,ReplicationSkipStopStart'
	],
	[
		'--rpl_mode=row',
		'--rpl_mode=mixed',
		'--rpl_mode=statement'
	],
	[
		'--engine=InnoDB',
		'--engine=MyISAM',
		'--engine=Aria'
	],
];
