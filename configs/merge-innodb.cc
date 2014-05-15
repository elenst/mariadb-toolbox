
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=5
		--duration=200
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--mysqld=--open-files-limit=1024
		--skip-shutdown
		--engine=InnoDB
		--mysqld=--log-output=FILE
		--mysqld=--log-bin
		--redefine=/home/elenst/mariadb-toolbox/grammars/innodb-5.6-redefine.yy
	'], 
	[
		'--grammar=conf/engines/concurrent.yy',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/engines/innodb/full_text_search.yy --gendata=conf/engines/innodb/full_text_search.zz',
	],
	[
		'--mysqld=--binlog-format=row --mysqld=--log-bin',
		'--mysqld=--binlog-format=statement --mysqld=--log-bin',
		''
	],
	[
		'--mysqld=--innodb-buffer-pool-size=4G',
		'--mysqld=--innodb-buffer-pool-size=256M'
	],
	[
		'--mysqld=--innodb-buffer-pool-size=4G',
		'--mysqld=--innodb-buffer-pool-size=256M'
	],
	[
		'--mysqld=--innodb-change-buffer-max-size=25',
		'--mysqld=--innodb-change-buffer-max-size=75',
	],
	[
		'--mysqld=--innodb-change-buffering=all',
		'--mysqld=--innodb-change-buffering=inserts',
		'--mysqld=--innodb-change-buffering=purges',
		'--mysqld=--innodb-change-buffering=none',
	],
	[
		'--mysqld=--innodb-file-per-table=ON',
		'--mysqld=--innodb-file-per-table=OFF',
	],
	[
		'--mysqld=--innodb-checksum-algorithm=innodb',
		'--mysqld=--innodb-checksum-algorithm=crc32',
		'--mysqld=--innodb-checksum-algorithm=none',
		'--mysqld=--innodb-checksum-algorithm=strict_innodb',
		'--mysqld=--innodb-checksum-algorithm=strict_crc32',
		'--mysqld=--innodb-checksum-algorithm=strict_none',
	],
	[
		'--mysqld=--innodb-cmp-per-index-enabled=ON',
		'--mysqld=--innodb-cmp-per-index-enabled=OFF',
	],
];

