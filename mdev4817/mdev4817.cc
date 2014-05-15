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
	'
	], 
	[
		'--views=MERGE',
		'--views=TEMPTABLE'
	],
	[
		'--grammar=/home/elenst/mariadb-toolbox/mdev4817/outer_join.yy --gendata=/home/elenst/mariadb-toolbox/mdev4817/outer_join.zz',
		'--grammar=/home/elenst/mariadb-toolbox/mdev4817/outer_join.yy --gendata=/home/elenst/mariadb-toolbox/mdev4817/outer_join.zz --notnull',
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

