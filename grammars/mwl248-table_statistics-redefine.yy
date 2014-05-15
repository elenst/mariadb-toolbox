# MDEV-3806:  Engine independent statistics (a.k.a. MWL#248)
# TODO-247 (testing task)

mdev_thread:
	mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats | 
	mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats |
	mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats |
	mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats | mdev_analyze_stats |
	mdev_set_use_stat_tables | mdev_set_use_stat_tables | 
	mdev_select_stat ;

thread1:
	mdev_thread ;

thread2:
       query | query | mdev_thread ;

mdev_analyze_stats:
	ANALYZE TABLE _table mdev_persistent_for |
	ANALYZE TABLE _basetable PERSISTENT FOR COLUMNS mdev_persistent_for_columns INDEXES  mdev_persistent_for_real_indexes
	;

mdev_persistent_for:
	| 
	PERSISTENT FOR ALL |
	PERSISTENT FOR COLUMNS mdev_persistent_for_columns |
	PERSISTENT FOR COLUMNS mdev_persistent_for_columns INDEXES mdev_persistent_for_columns ;

mdev_persistent_for_columns:
	ALL | ( mdev_columns ) ;

mdev_persistent_for_real_indexes:
	ALL | ( mdev_indexes ) ;
	
mdev_columns:
	 | | _field | _field | _field, _field, _field, _field ;

mdev_indexes:
	 | | 
	PRIMARY |
	mdev_indexed | mdev_indexed | 
	mdev_indexed, mdev_indexed, mdev_indexed, mdev_indexed |
# Hoping to create an existing multi-part index name sometimes
	{ '`'.$prng->arrayElement($fields_indexed).'_'.$prng->arrayElement($fields_indexed).'`' }
;

mdev_indexed:
	_field_key | _field_key | _field_key | _field_key | _field ;

mdev_set_use_stat_tables:
	SET mdev_scope use_stat_tables = mdev_use_stat_tables ;

mdev_use_stat_tables:
	PREFERABLY | COMPLEMENTARY | NEVER ;

mdev_scope:
	| SESSION | GLOBAL ;

mdev_stat_table:
	`mysql` . `table_stats` | `mysql` . `column_stats` | `mysql` . `index_stats` ;

mdev_select_stat:
	SELECT * FROM mdev_stat_table WHERE `table_name` = '_table' ;

