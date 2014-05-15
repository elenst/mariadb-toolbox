# Might need to modify MAX_ROWS_THRESHOLD 

$combinations = [
	[
	'
		--debug
		--no-mask
		--notnull
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
		--mysqld1=--optimizer_switch=extended_keys=on 
		--mysqld2=--optimizer_switch=extended_keys=off
		--engine=InnoDB
		--querytimeout=40
		--rows=0,1,10,1000,100000,0,2,20,50,200
	'], [
		'--grammar=conf/optimizer/optimizer_subquery.yy',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple.yy'
	], 
	[
		'--views=MERGE',
		'--views=TEMPTABLE',
		'--views'
	],
	[
		'--skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		''
	],
];
