$combinations = [
	['
		--no-mask
		--seed=time
		--threads=5
		--duration=400
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld=--log-output=FILE
		--mysqld1=--optimizer-switch=condition_pushdown_for_derived=off
		--mysqld2=--optimizer-switch=condition_pushdown_for_derived=on
		--querytimeout=60
	'], 
	[
		'--grammar=conf/mariadb/optimizer.yy --gendata=conf/mariadb/optimizer.zz',
		'--grammar=conf/mariadb/optimizer.yy --views=TEMPTABLE',
		'--grammar=conf/mariadb/optimizer.yy --notnull --views=TEMPTABLE',
		'--grammar=conf/mariadb/optimizer.yy --views=MERGE',
		'--grammar=conf/mariadb/optimizer.yy --notnull --views=MERGE',
		'--grammar=conf/mariadb/optimizer.yy --skip-gendata --mysqld=--init-file=$RQG_HOME/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/outer_join.yy --gendata=conf/optimizer/outer_join.zz',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --views=TEMPTABLE',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --notnull --views=TEMPTABLE',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --views=MERGE',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --notnull --views=MERGE',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --skip-gendata --mysqld=--init-file=$RQG_HOME/conf/mariadb/world.sql',
	], 
	[
		'--engine=MyISAM',
		'--engine=InnoDB',
	],
];
