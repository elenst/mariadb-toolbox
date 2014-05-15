
$combinations = [
	[
	'
		--debug
		--no-mask
		--seed=time
		--threads=4
		--duration=600
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--validator=ResultsetComparatorSimplify
		--mysqld1=--innodb_stats_sample_pages=256
		--mysqld1=--max_join_size=100000000
		--mysqld1=--log-output=FILE
		--mysqld2=--innodb_stats_sample_pages=256
		--mysqld2=--max_join_size=100000000
		--mysqld2=--log-output=FILE
		--mysqld1=--optimizer_switch=mrr=on,mrr_sort_keys=on
		--mysqld2=--optimizer_switch=mrr=off,mrr_sort_keys=off
	'], 
	[
		'--mysqld1=--join-cache-level=6 --mysqld2=--join-cache-level=6'
	],
	[
		'--engine=InnoDB',
		'--engine=Aria',
		'--engine=MyISAM'
	],
	[
		'--grammar=conf/optimizer/optimizer_subquery.yy',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple.yy',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz'
	], 
	[
		'--views=MERGE',
		'--views=TEMPTABLE',
		'--views'
	],
];
