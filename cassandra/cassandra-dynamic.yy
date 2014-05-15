#
# Cassandra tables with dynamic fields. 
# To be used with cassandra.zz
#

query_init:
	CREATE TABLE _tmptable ( `pk` INT PRIMARY KEY, `dyncol` BLOB DYNAMIC_COLUMN_STORAGE=yes ) 
	ENGINE=CASSANDRA KESPACE='rqg' COLUMN_FAMILY='cf1' ; CREATE TABLE IF NOT EXISTS D1 LIKE _tmptable ;

dyntable:
	D1 | _tmptable;

mytable:
	_table | _table | dyntable ;

query:
	transaction |
	analyze |
	create_dyncol_record | add_dynamic_value | check_dyncol_exists | get_dyncol_value | check_dyncol_value | 
	select | select |
	select | select |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete ;

analyze:
	ANALYZE TABLE mytable ;

create_dyncol_record:
	UPDATE dyntable SET `dyncol` = COLUMN_CREATE( dynamic_values ) where;

dynamic_values:
	dynfield, value | dynamic_values, dynfield, dynvalue ;

dynfield:
	"dynA" | "dynB" | "dynC" | "dynD" | "dynE" | "dynF" | "dynG" | "dynH" | "dynI" | "dynJ" | "dynK" | "dynL" ;

dynvalue:
	_int | _tinyint | _varchar(8) | NULL | '' ;

add_dynamic_value:
	UPDATE dyntable SET `dyncol` = COLUMN_ADD( `dyncol`, dynamic_values ) where;

check_dyncol_exists:
	SELECT `pk`, COLUMN_EXISTS( `dyncol`, dynfield ) FROM dyntable where ;

get_dyncol_value:
	SELECT `pk`, COLUMN_GET( `dyncol`, dynfield AS dyntype ), COLUMN_JSON( `dyncol` ) FROM dyntable where ;

check_dyncol_value:
	SELECT `pk`, COLUMN_CHECK( `dyncol` ) FROM dyntable where ;

dyntype:
	BINARY | BINARY(_digit) | CHAR | CHAR(_digit) | DATE | DATETIME | DATETIME(microseconds) | 
	DECIMAL | DECIMAL(_digit) | DECIMAL(precision1, _digit) | DOUBLE | DOUBLE(precision1,_digit) |
	INT | SIGNED | TIME | TIME(microseconds) | UNSIGNED | unknown | NULL ;

precision1:
	_digit | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 ;

microseconds:
	0 | 1 | 2 | 3 | 4 | 5 | 6 ;

dyncol_table_field_list:
	

dyncol_table_name:
	D1 | D2 | D3 | D4 | D5 | D6 | D7 | D8;

transaction:
	START TRANSACTION |
	COMMIT ; SET TRANSACTION ISOLATION LEVEL isolation_level |
	ROLLBACK ; SET TRANSACTION ISOLATION LEVEL isolation_level |
	SAVEPOINT A | ROLLBACK TO SAVEPOINT A |
	SET AUTOCOMMIT=OFF | SET AUTOCOMMIT=ON ;

isolation_level:
	READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SERIALIZABLE ;

select:
	SELECT select_list FROM join_list where LIMIT large_digit for_update_lock_in_share_mode;

select_list:
	X . _field | X . _field |
	X . `pk` |
	X . _field |
	* |
	( subselect );

subselect:
	SELECT _field FROM mytable WHERE `pk` = value ;

join_list:
	mytable AS X | 
	mytable AS X LEFT JOIN mytable AS Y USING ( _field );

for_update_lock_in_share_mode:
	| | | | | 
	FOR UPDATE |
	LOCK IN SHARE MODE ;

insert_replace:
	i_r INTO mytable (`pk`) VALUES (NULL) |
	i_r INTO mytable ( _field_no_pk , _field_no_pk ) VALUES ( value , value ) , ( value , value ) |
	i_r INTO mytable ( _field_no_pk ) SELECT _field FROM mytable AS X where ORDER BY _field_list LIMIT large_digit;

i_r:
	INSERT low_priority |
	INSERT low_priority IGNORE |
	REPLACE low_priority;

ignore:
	| 
	IGNORE ;

low_priority:
	LOW_PRIORITY;

update:
	UPDATE low_priority ignore mytable AS X SET _field_no_pk = value where ORDER BY _field_list LIMIT large_digit ;

# We use a smaller limit on DELETE so that we delete less than we insert

delete:
	DELETE low_priority quick ignore FROM mytable where_delete ORDER BY _field_list LIMIT small_digit ;

quick:
	| 
	QUICK ;

order_by:
	| ORDER BY X . _field ;

# Use an index at all times
where:
	|
	WHERE X . _field < value | 	# Use only < to reduce deadlocks
	WHERE X . _field IN ( value , value , value , value , value ) |
	WHERE X . _field BETWEEN small_digit AND large_digit |
	WHERE X . _field BETWEEN _tinyint_unsigned AND _int_unsigned |
	WHERE X . _field = ( subselect ) ;

where_delete:
	|
	WHERE _field = value |
	WHERE _field IN ( value , value , value , value , value ) |
	WHERE _field IN ( subselect ) |
	WHERE _field BETWEEN small_digit AND large_digit ;

large_digit:
	5 | 6 | 7 | 8 ;

small_digit:
	1 | 2 | 3 | 4 ;

value:
	_digit | _tinyint_unsigned | _varchar(1) | _int_unsigned ;

zero_one:
	0 | 0 | 1;
