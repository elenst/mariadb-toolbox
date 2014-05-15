
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--mysqld=--log-output=FILE
	'], 
	[
		'--grammar=conf/mariadb/bug1008293-1.yy --duration=300 --threads=2 --skip-gendata',
		'--grammar=conf/mariadb/bug1008293-2.yy --duration=300 --threads=2 --engine=MyISAM'
	], 
];
