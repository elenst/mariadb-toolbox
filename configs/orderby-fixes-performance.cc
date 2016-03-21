$combinations = [
	['
		--no-mask
		--seed=time
		--threads=1
		--duration=1200
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--validators=ExecutionTimeComparator
		--redefine=conf/mariadb/analyze-tables-at-start.yy
		--mysqld=--log-output=FILE
		--querytimeout=300
		--mysqld=--innodb_flush_log_at_trx_commit=2
	'], 
	[
		'--grammar=$HOME/mariadb-toolbox/grammars/orderby-fixes-optimizer.yy --engine=MyISAM --rows=0,1,20,100,1000,5,50,500,5000',
		'--grammar=$HOME/mariadb-toolbox/grammars/orderby-fixes-optimizer.yy --engine=InnoDB --rows=0,1,20,100,1000,5,50,500,5000',
		'--grammar=$HOME/mariadb-toolbox/grammars/orderby-fixes-range_access.yy --gendata=$HOME/mariadb-toolbox/grammars/orderby-fixes-range_access.zz',
		'--grammar=$HOME/mariadb-toolbox/grammars/orderby-fixes-range_access2.yy --gendata=$HOME/mariadb-toolbox/grammars/orderby-fixes-range_access2.zz',
	], 
	[	'
			--mysqld=--use_stat_tables=PREFERABLY
			--mysqld=--optimizer_use_condition_selectivity=5 
			--mysqld=--histogram_size=100 
			--mysqld=--histogram_type=DOUBLE_PREC_HB
		',
		''
	]
];
