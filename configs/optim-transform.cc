$combinations = [
	['
		--no-mask
		--seed=time
		--threads=4
		--duration=300
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--validator=Transformer
		--transformers=DisableChosenPlan,ExecuteAsDerived,ExecuteAsTrigger,DisableJoinCache,ExecuteAsPreparedTwice,ExecuteAsUpdateDelete
		--mysqld=--innodb_stats_sample_pages=256
		--mysqld=--max_join_size=1000000
		--mysqld=--log-output=FILE
	'], 
	[
		'--notnull',
		''
	],
	[
		'',
		'--skip-gendata --mysqld=--init-file=/home/elenst/bzr/randgen-mariadb-patches/conf/mariadb/world.sql'
	],
	[
		'--grammar=conf/optimizer/optimizer_subquery.yy',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/optimizer_subquery_simple.yy',
		'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy',
		'--grammar=conf/optimizer/outer_join.yy',
		'--grammar=conf/optimizer/updateable_views.yy',
		'--grammar=conf/optimizer/optimizer_no_subquery.yy',
		'--grammar=conf/optimizer/optimizer_access_exp.yy',
	], 
	[
		'',
		'--mysqld=--join-cache-level=8',
	],
	[
		'--views=MERGE',
		'--views=TEMPTABLE'
	],
	[
		'--engine=Aria',
		'--engine=MyISAM',
		'--engine=InnoDB'
	],
];
