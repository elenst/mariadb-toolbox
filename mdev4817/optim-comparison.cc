#
# 48-hours long test set (net time) 
#

$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=4
		--duration=300
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock
		--mysqld1=--log-output=FILE
		--mysqld2=--log-output=FILE
		--views
	'
	], 
	[
		'--grammar=conf/optimizer/optimizer_subquery.yy',
		'--grammar=conf/optimizer/optimizer_subquery.yy --notnull',
		'--grammar=conf/optimizer/optimizer_subquery.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy --notnull',
		'--grammar=conf/optimizer/optimizer_subquery_semijoin.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy',
		'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy --notnull',
		'--grammar=conf/optimizer/optimizer_subquery_no_outer_join.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/outer_join.yy --gendata=conf/optimizer/outer_join.zz',
		'--grammar=conf/optimizer/outer_join.yy --gendata=conf/optimizer/outer_join.zz --notnull',
		'--grammar=conf/optimizer/updateable_views.yy',
		'--grammar=conf/optimizer/updateable_views.yy --notnull',
		'--grammar=conf/optimizer/updateable_views.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/optimizer_no_subquery.yy',
		'--grammar=conf/optimizer/optimizer_no_subquery.yy --notnull',
		'--grammar=conf/optimizer/optimizer_no_subquery.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/optimizer_access_exp.yy',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --notnull',
		'--grammar=conf/optimizer/optimizer_access_exp.yy --skip-gendata --mysqld1=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql --mysqld2=--init-file=/home/elenst/bzr/rangen-mariadb-patches/conf/mariadb/world.sql',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz',
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz --notnull',
	], 
	[
		'',
		'--mysqld1=--join-cache-level=8 --mysqld2=--join-cache-level=8',
	],
	[
		'--mysqld1=--optimizer_prune_level=0 --mysqld2=--optimizer_prune_level=0',
		'--mysqld1=--optimizer_prune_level=1 --mysqld2=--optimizer_prune_level=1'
	],
	[
		'--engine=Aria',
		'--engine=MyISAM',
		'--engine=InnoDB'
	],
];

