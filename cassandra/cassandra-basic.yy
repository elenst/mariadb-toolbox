#
# Basic grammar for Cassandra tests. 
# To be used with cassandra.zz
#

query:
	transaction |
	select | select |
	select | select |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete |
	insert_replace | update | delete ;

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
	SELECT _field FROM _table WHERE `pk` = value ;

# Use index for all joins
join_list:
	_table AS X | 
	_table AS X LEFT JOIN _table AS Y USING ( _field );

for_update_lock_in_share_mode:
	| | | | | 
	FOR UPDATE |
	LOCK IN SHARE MODE ;

# Insert more than we delete
insert_replace:
	i_r INTO _table (`pk`) VALUES (NULL) |
	i_r INTO _table ( _field_no_pk , _field_no_pk ) VALUES ( value , value ) , ( value , value ) |
	i_r INTO _table ( _field_no_pk ) SELECT _field FROM _table AS X where ORDER BY _field_list LIMIT large_digit;

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
	UPDATE low_priority ignore _table AS X SET _field_no_pk = value where ORDER BY _field_list LIMIT large_digit ;

# We use a smaller limit on DELETE so that we delete less than we insert

delete:
	DELETE low_priority quick ignore FROM _table where_delete ORDER BY _field_list LIMIT small_digit ;

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
