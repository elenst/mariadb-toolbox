
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
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--validator=ResultsetComparatorSimplify
		--mysqld1=--innodb_stats_sample_pages=256
		--mysqld1=--max_join_size=1000000
		--mysqld1=--log-output=FILE
		--mysqld2=--innodb_stats_sample_pages=256
		--mysqld2=--max_join_size=1000000
		--mysqld2=--log-output=FILE
		--mysqld1=--optimizer_switch=exists_to_in=on 
	'], [
		'--grammar=/home/elenst/mariadb-toolbox/grammars/exists2in.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/exists2in_semijoin.yy',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/exists2in_simple.yy'
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
	[
		'--mysqld1=--join-cache-level=2 --mysqld2=--join-cache-level=2',
		'--mysqld1=--join-cache-level=8 --mysqld2=--join-cache-level=8'
	],
        [
                '--engine=Aria',
                '--engine=MyISAM',
                '--engine=InnoDB'
        ],

];
