query_init:
	alter_add ; alter_add ; alter_add ; alter_add ; alter_add ;

query:
	alter_drop_add |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select |
	select | select | select | select | select ;

select:
	SELECT distinct * FROM _table index_hint WHERE where order_by /* limit */ |
	SELECT distinct * FROM _table index_hint WHERE where order_by /* limit */ |
	SELECT distinct * FROM _table index_hint WHERE where order_by /* limit */ |
	SELECT distinct * FROM _table index_hint WHERE where order_by /* limit */ |
	SELECT aggregate int_key ) FROM _table index_hint WHERE where |
	SELECT int_key , aggregate int_key ) FROM _table index_hint WHERE where GROUP BY 1 ;

alter_add:
	ALTER TABLE _table ADD KEY key1 ( index_list ) ;

alter_drop_add:
	ALTER TABLE _table DROP KEY key1 ; ALTER TABLE _table[invariant] ADD KEY key1 ( index_list ) ;

distinct:
	| | DISTINCT ;

order_by:
	| ORDER BY order_by_list | ORDER BY order_by_key_list | ORDER BY `pk` asc_desc;

order_by_list:
	_field asc_desc | _field asc_desc, order_by_list ;

order_by_key_list:
	any_key asc_desc | any_key asc_desc, order_by_key_list;

asc_desc:
	| ASC | DESC ;

limit:
	| | | | |
	| LIMIT _digit;
	| LIMIT _tinyint_unsigned;

where:
	where_list and_or where_list | where_list | where_list and_or where_list or_and where_list ;

where_list:
	where_two and_or ( where_list ) |
	where_two and_or where_two |
	where_two and_or where_two and_or where_two |
	where_two ;

where_two:
	( integer_item or_and integer_item ) |
	( string_item or_and string_item );

integer_item:
	not ( int_key comparison_operator integer_value ) |
	int_key not BETWEEN integer_value AND integer_value + integer_value |
	int_key not IN ( integer_list ) |
	int_key IS not NULL ;

string_item:
	not ( string_key comparison_operator string_value ) |
	string_key not BETWEEN string_value AND string_value |
	string_key not LIKE CONCAT (string_value , '%' ) |
	string_key not IN ( string_list ) |
	string_key IS not NULL ;

aggregate:
	MIN( | MAX( | COUNT( ;

and_or:
	AND | AND | AND | AND | OR ;
or_and:
	OR | OR | OR | OR | AND ;

integer_value:
	_digit | _digit |
	_tinyint | _tinyint_unsigned |
	255 | 1 ;

string_value:
	_varchar(1) | _varchar(2) | _english | _states | _varchar(10) ;

integer_list:
	integer_value , integer_value |
	integer_value , integer_list ;

string_list:
	string_value , string_value |
	string_value , string_list ;

comparison_operator:
	= | = | = | = | = | = |
	!= | > | >= | < | <= | <> ;

not:
	| | | NOT ;

any_key:
	int_key | string_key ;

int_key:
	`pk` | `col_smallint_key` | `col_bigint_key` ;

string_key:
	`col_varchar_10_key` | `col_varchar_256_key` ;

index_list:
	index_item , index_item |
	index_item , index_list;

index_item:
	_field | _field |
	int_key | string_key ( index_length ) ;

index_length:
	1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 ;

index_hint:
	| | | 
	FORCE KEY ( PRIMARY , `col_smallint_key` , `col_bigint_key` ,  `col_varchar_10_key` , `col_varchar_256_key` );
