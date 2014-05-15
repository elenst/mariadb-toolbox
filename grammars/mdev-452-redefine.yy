thread1:
	mdev_column_thread ;

thread2:
	mdev_column_thread ;

mdev_column_thread:
	mdev_add_temp_col | 
	mdev_drop_temp_col | 
	mdev_insert | mdev_insert | mdev_insert | 
	mdev_update | mdev_update |
	mdev_load | 
	mdev_show |
	mdev_select 
;

# mdev_extra_* entries are reserved for queries not compatible 
# with other versions or implementations of the feature,
# and thus unusable for comparison tests;
# e.g. in this case we can't include virtual columns
# into the grammar because it should be used for comparison
# with MySQL 5.6

mdev_add_temp_col:
	mdev_add_col | mdev_add_col | mdev_add_col | mdev_extra_add_vcol ;

mdev_extra_add_vcol:
	;

mdev_add_col:
	ALTER TABLE _table ADD COLUMN mdev_col_name mdev_temp_col_def;

mdev_drop_temp_col:
	ALTER TABLE _table DROP COLUMN mdev_col_name;

mdev_temp_col_def:
	mdev_col_type mdev_null_not_null mdev_default mdev_on_update |
	mdev_col_type_msec0 mdev_null_not_null mdev_default mdev_on_update |
	mdev_col_type_msec0 mdev_null_not_null mdev_default_msec0 mdev_on_update_msec0 |
	mdev_col_type_msec1 mdev_null_not_null mdev_default_msec1 mdev_on_update_msec1 |
	mdev_col_type_msec4 mdev_null_not_null mdev_default_msec4 mdev_on_update_msec4 |
	mdev_col_type_msec6 mdev_null_not_null mdev_default_msec6 mdev_on_update_msec6 ;

mdev_col_type:
	DATETIME | TIMESTAMP ;

mdev_col_type_msec0:
	mdev_col_type (0);

mdev_col_type_msec1:
	mdev_col_type (1);

mdev_col_type_msec4:
	mdev_col_type (4);

mdev_col_type_msec6:
	mdev_col_type (6);

mdev_null_not_null:
	| NULL | NOT NULL ;

mdev_default:
	mdev_default_const | mdev_default_const |
	DEFAULT NOW() | 
	DEFAULT CURRENT_TIMESTAMP | 
	DEFAULT CURRENT_TIMESTAMP() | 
	DEFAULT LOCALTIME | 
	DEFAULT LOCALTIMESTAMP() ; 

mdev_default_const:
	| 
	DEFAULT 0 | 
	DEFAULT '2012-12-12 12:12:12' |
	DEFAULT '2012-12-12 12:12:12.1' | 
	DEFAULT '2012-12-12 12:12:12.12' | 
	DEFAULT '2012-12-12 12:12:12.1212' | 
	DEFAULT '2012-12-12 12:12:12.121212' | 
	DEFAULT NULL ;

mdev_default_msec0:
	mdev_default_const | mdev_default_const |
	DEFAULT NOW(0) | 
	DEFAULT CURRENT_TIMESTAMP(0) | 
	DEFAULT LOCALTIME(0) ;

mdev_default_msec1:
	mdev_default_const | mdev_default_const |
	DEFAULT NOW(1) | 
	DEFAULT CURRENT_TIMESTAMP(1) | 
	DEFAULT LOCALTIME(1) ;

mdev_default_msec4:
	mdev_default_const | mdev_default_const |
	DEFAULT NOW(4) | 
	DEFAULT CURRENT_TIMESTAMP(4) | 
	DEFAULT LOCALTIME(4) ;

mdev_default_msec6:
	mdev_default_const | mdev_default_const |
	DEFAULT NOW(6) | 
	DEFAULT CURRENT_TIMESTAMP(6) | 
	DEFAULT LOCALTIME(6) ;

mdev_on_update:
	| 
	ON UPDATE CURRENT_TIMESTAMP ; 

mdev_on_update_msec0:
	ON UPDATE CURRENT_TIMESTAMP(0) ;

mdev_on_update_msec1:
	ON UPDATE CURRENT_TIMESTAMP(1) ;

mdev_on_update_msec4:
	ON UPDATE CURRENT_TIMESTAMP(4) ;

mdev_on_update_msec6:
	ON UPDATE CURRENT_TIMESTAMP(6) ;

mdev_insert:
	INSERT mdev_delayed INTO _table () VALUES () |
	INSERT mdev_delayed INTO _table ( mdev_col_name ) VALUES ( mdev_null_or_default ),( mdev_null_or_default ) | 
	INSERT mdev_delayed INTO _table ( _field, mdev_col_name ) VALUES ( mdev_null_or_default, mdev_null_or_default ) | 
	INSERT mdev_delayed INTO _table ( _field, mdev_col_name ) 
		VALUES ( DEFAULT, mdev_null_or_default ) 
		ON DUPLICATE KEY UPDATE mdev_col_name = mdev_null_or_default ; 

mdev_update:
	UPDATE _table SET _field = DEFAULT WHERE mdev_col_name < NOW() |
	UPDATE _table AS alias1, _table AS alias2 SET alias1 . _field = _field WHERE alias1 . mdev_col_name < NOW() |
	UPDATE _table SET mdev_col_name = CURRENT_TIMESTAMP WHERE _field > _field |
	UPDATE _table AS alias1, _table AS alias2 SET alias2 . mdev_col_name = CURRENT_TIMESTAMP WHERE alias1 . _field > _field 
;

mdev_delayed:
	| | | | | DELAYED ;

mdev_null_or_default:
	NULL | DEFAULT ;

# On some reason _tmpnam doesn't want to work (doesn't get removed)

mdev_load:
	mdev_load_data | mdev_load_xml ;

mdev_load_data:
	LOAD DATA INFILE { "'".'/home/elenst/mariadb-toolbox/data/mdev452.load'."'" } INTO TABLE _table mdev_terminated_enclosed_by mdev_load_field_list ;

mdev_load_xml: 
	LOAD XML INFILE { "'".'/home/elenst/mariadb-toolbox/data/mdev452.xml'."'" } INTO TABLE _table mdev_load_field_list_or_empty ;

mdev_terminated_enclosed_by:
	| | FIELDS TERMINATED BY '' ENCLOSED BY '' ;

mdev_load_field_list:
	( mdev_col_name ) | ( mdev_col_name, mdev_col_name ) ;

mdev_load_field_list_or_empty:
	| mdev_load_field_list ;

mdev_show:
	SHOW CREATE TABLE _table ;

mdev_col_name:
	`mdev_1` | `mdev_2` | `mdev_3` ;

mdev_select:
	SELECT * FROM _table ;


