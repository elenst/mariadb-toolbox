# Note: this grammar requires DBT3 data be prepared in advance,
# and might also need to modify default schema name in runall.pl
# and MAX_ROWS_THRESHOLD

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
		--skip-gendata
		--mysqld1=--datadir=/home/elenst/data-dbt3-sf1-innodb-1
		--mysqld2=--datadir=/home/elenst/data-dbt3-sf1-innodb-2
	'], 
	[
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_dbt3.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_semijoin_dbt3.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple_dbt3.yy',
		'--grammar=conf/dbt3/dbt3-joins.yy',
		'--grammar=conf/dbt3/dbt3-dml.yy',
		'--grammar=conf/dbt3/dbt3-ranges.yy'
	], 
	[
		'--views=MERGE',
		'--views=TEMPTABLE',
		'--views'
	],
];

