$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=4
		--duration=600
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--validators=Transformer,ResultsetComparator
		--transformers=DisableChosenPlan
		--mysqld1=--log-output=FILE
		--mysqld2=--log-output=FILE
		--mysqld1=--default-storage-engine=Aria
		--mysqld2=--default-storage-engine=MyISAM
	'
	], 
	[
		'--grammar=conf/optimizer/range_access.yy --gendata=conf/optimizer/range_access.zz --views',
		'--grammar=conf/optimizer/range_access2.yy --gendata=conf/optimizer/range_access2.zz --views',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/mdev4687.yy --skip-gendata --mysqld1=--init-file=/home/elenst/mariadb-toolbox/data/mdev4687.dump --mysqld1=--init-file=/home/elenst/mariadb-toolbox/data/mdev4687.dump',
		'--grammar=/home/elenst/mariadb-toolbox/grammars/mdev4687.yy --skip-gendata --mysqld1=--init-file=/home/elenst/mariadb-toolbox/data/mdev4687-more-data.dump --mysqld1=--init-file=/home/elenst/mariadb-toolbox/data/mdev4687-more-data.dump'
	],
	[
		'--mysqld1=--optimizer_prune_level=0 --mysqld2=--optimizer_prune_level=0',
		'--mysqld1=--optimizer_prune_level=1 --mysqld2=--optimizer_prune_level=1'
	],
];
