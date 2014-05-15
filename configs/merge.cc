
$combinations = [
	[
	'
		--no-mask
		--seed=time
		--threads=4
		--duration=200
		--queries=100M
		--reporters=QueryTimeout,Backtrace,ErrorLog,Deadlock,Shutdown
		--mysqld=--open-files-limit=1024
		--skip-shutdown
	'], 
	[
		'--grammar=conf/dyncol/dyncol_dml.yy --gendata=conf/dyncol/dyncol_dml.zz',
		'--grammar=conf/engines/blobs.yy',
		'--grammar=conf/engines/concurrent.yy',
		'--grammar=conf/engines/engine_stress.yy --gendata=conf/engines/engine_stress.zz',
		'--grammar=conf/engines/handler.yy --gendata=conf/engines/handler.zz',
		'--grammar=conf/engines/many_indexes.yy --gendata=conf/engines/many_indexes.zz',
		'--grammar=conf/engines/tiny_inserts.yy --gendata=conf/engines/tiny_inserts.zz',
		'--grammar=conf/engines/varchar.yy --gendata=conf/engines/varchar.zz',
		'--grammar=conf/engines/innodb/full_text_search.yy --gendata=conf/engines/innodb/full_text_search.zz',
		'--grammar=conf/engines/heap/heap_ddl_multi.yy',
		'--mysqld=--init_file='.cwd().'/conf/engines/heap/heap_dml_single.init --grammar=conf/engines/heap/heap_dml_single.yy --skip-gendata',
		'--grammar=conf/engines/maria/maria_stress.yy',
		'--grammar=conf/engines/maria/maria_mostly_selects.yy',
		'--grammar=conf/engines/maria/maria_bulk_insert.yy',
		'--grammar=conf/engines/maria/maria_dml_alter.yy',
		'--grammar=conf/gis/gis.yy',
		'--grammar=conf/i18n/collations.yy',
		'--grammar=conf/partitioning/partition_pruning.yy --gendata=conf/partitioning/partition_pruning.zz',
		'--grammar=conf/partitioning/partitions-ddl.yy',
		'--grammar=conf/partitioning/partitions_hash_key_less_rand.yy',
		'--grammar=conf/partitioning/partitions_less_rand.yy',
		'--grammar=conf/partitioning/partitions_procedures_triggers.yy',
		'--grammar=conf/partitioning/partitions.yy',
		'--short_column_names --grammar=conf/temporal/current_timestamp_6.yy --gendata=conf/temporal/current_timestamp_6.zz',
		'--short_column_names --grammar=conf/temporal/current_timestamp.yy --gendata=conf/temporal/current_timestamp.zz',
		'--grammar=conf/temporal/temporal_functions.yy --gendata=conf/temporal/temporal_functions.zz',
		'--grammar=conf/temporal/temporal_functions.yy --gendata=conf/temporal/temporal_functions-wl946.zz',
		'--grammar=conf/temporal/temporal_ranges.yy --gendata=conf/temporal/temporal_ranges.zz',
		'--grammar=conf/temporal/temporal_replication.yy',
		'--grammar=conf/transactions/combinations.yy --gendata=conf/transactions/combinations.zz',
		'--grammar=conf/transactions/transactions.yy --gendata=conf/transactions/transactions.zz',
		'--grammar=conf/transactions/transactions-flat.yy --gendata=conf/transactions/transactions.zz',
		'--grammar=conf/transactions/transaction_durability.yy --gendata=conf/transactions/transactions.zz',
		'--grammar=conf/transactions/repeatable_read.yy',
	],
	[
		'--engine=InnoDB',
		'--engine=MyISAM',
		'--engine=Aria',
	],
# slave-skip-errors: 
# 1054: MySQL:67878 (LOAD DATA in views)
# 1317: Query partially completed on the master (MDEV-368 which won't be fixed)
# 1049, 1305, 1539: MySQL:65428 (Unknown database) - fixed in 5.7.0
# 1505: MySQL:64041 (Partition management on a not partitioned table) 
	[
		'--rpl_mode=row',
		''
	],
	[
		'--mysqld=--log-output=FILE',
	]
];

