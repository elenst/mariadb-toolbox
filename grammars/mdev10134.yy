query_init:
    { $local_table = 'tbl_'.$generator->threadId(); '' };
    
my_table:
      tbl_shared 
    | { $local_table } 
    | { $local_table } 
    | { $local_table } 
    | { $local_table } 
;

query:
      CREATE OR REPLACE temporary TABLE my_table ( column_list ) ENGINE = engine
    | INSERT INTO my-table () VALUES (), ();
    
column_list:
    { $ncol = 1; '' } columns indexes ;

# TODO
indexes:
;
    
columns:
      column_desc 
    | columns, column_desc
;
    
column_desc:
    { 'col' . $ncol++ } column_def default_clause ;
    
default_clause:
    DEFAULT ( select_item );
    
null_not_null:
    | NULL 
    | NOT NULL 
;
    
unsigned_opt:
    | UNSIGNED ;
    
zerofill_opt:
    | ZEROFILL;
    
length_opt:
    | ( length ) ;
    
length:
    { $length = int(rand($max_length+1)) } ;

length_opt_decimal_opt:
      length_opt 
    | ( length decimal_opt )
;


length_decimal_opt:
    | ( length, decimals ) ;
    
decimal_opt:
    | , decimals;
    
decimals:
    { $max_scale = $length if $length < $max_scale; int(rand($max_scale+1)) } ;

binary_opt:
    | BINARY ;
    
charset_opt:
    | CHARACTER SET charset_name;
    
collate_opt:
    | COLLATE collation_name;
    
# TODO
charset_name:
    UTF8;
    
# TODO
collation_name:
    utf8_bin ;

column_def:
    { $max_length = 64; '' } BIT length_opt
  | TINYINT length_opt unsigned_opt zerofill_opt
  | SMALLINT length_opt unsigned_opt zerofill_opt
  | MEDIUMINT length_opt unsigned_opt zerofill_opt
  | INT length_opt unsigned_opt zerofill_opt
  | INTEGER length_opt unsigned_opt zerofill_opt
  | BIGINT length_opt unsigned_opt zerofill_opt
  | REAL    { $max_length = 255; $max_scale = 30; '' } length_decimal_opt unsigned_opt zerofill_opt
  | DOUBLE  { $max_length = 255; $max_scale = 30; '' } length_decimal_opt unsigned_opt zerofill_opt
  | FLOAT   { $max_length = 255; $max_scale = 30; '' } length_decimal_opt unsigned_opt zerofill_opt
  | DECIMAL { $max_length = 65; $max_scale = 38; '' }  length_opt_decimal_opt unsigned_opt zerofill_opt
  | NUMERIC { $max_length = 65; $max_scale = 38; '' }  length_opt_decimal_opt unsigned_opt zerofill_opt
  | DATE
  | TIME
  | TIMESTAMP
  | DATETIME
  | YEAR
  | CHAR length_opt binary_opt
      charset_opt collate_opt
  | VARCHAR (length) binary_opt
      charset_opt collate_opt
  | BINARY length_opt
  | VARBINARY (length)
  | TINYBLOB
  | BLOB
  | MEDIUMBLOB
  | LONGBLOB
  | TINYTEXT binary_opt
      charset_opt collate_opt
  | TEXT binary_opt
      charset_opt collate_opt
  | MEDIUMTEXT binary_opt
      charset_opt collate_opt
  | LONGTEXT binary_opt
      charset_opt collate_opt
  | ENUM( enum_value_list )
      charset_opt collate_opt
  | SET( enum_value_list )
      charset_opt collate_opt
# TODO
#  | spatial_type
;

enum_value_list:
    _char | _char, enum_value_list ;

engine:
    InnoDB | MyISAM | Aria | MEMORY ;

# TODO
prepare_execute:
    SET @stmt = " select "; SET @stmt_create = CONCAT("CREATE TEMPORARY TABLE `ps` AS ", @stmt ); PREPARE stmt FROM @stmt_create ; EXECUTE stmt ; SET @stmt_ins = CONCAT("INSERT INTO `ps` ", @stmt) ; PREPARE stmt FROM @stmt_ins; EXECUTE stmt; EXECUTE stmt; DEALLOCATE stmt; DROP TEMPORARY TABLE `ps`;

temporary:
   | TEMPORARY ;

# TODO
select:
   { $num = 0; '' } explain_extended SELECT distinct select_list FROM _table where group_by_having_order_by_limit;

# TODO
select_list:
   select_item AS { $num++; 'field'.$num } | select_item AS { $num++; 'field'.$num } , select_list ;

distinct:
   | DISTINCT ; 

select_item:
   func 
#### Not supported
####   | aggregate_func
;

aggregate_func:
      COUNT( func )  
    | AVG( func )  
    | SUM( func ) 
    | MAX( func )  
    | MIN( func ) 
    | GROUP_CONCAT( func, func ) 
    | BIT_AND( arg ) 
    | BIT_COUNT( arg ) 
    | BIT_LENGTH( arg ) 
    | BIT_OR( arg ) 
    | BIT_XOR( arg ) 
    | STD( arg ) 
    | STDDEV( arg ) 
    | STDDEV_POP( arg ) 
    | STDDEV_SAMP( arg ) 
    | VAR_POP( arg )
    | VAR_SAMP( arg )
    | VARIANCE( arg )
;

where:
   | WHERE func ;

group_by_having_order_by_limit:
      group_by_with_rollup having limit
    | group_by having order_by limit 
;

group_by_with_rollup:
    | GROUP BY func WITH ROLLUP 
    | GROUP BY func, func WITH ROLLUP ;

group_by:
   | GROUP BY func 
   | GROUP BY func, func ;

having:
   | HAVING func ;

order_by:
   | ORDER BY func 
   | ORDER BY func, func ;

limit:
   | | | LIMIT _tinyint_unsigned ;

func:
      math_func 
    | arithm_oper 
    | comparison_oper 
    | logical_or_bitwise_oper 
#### Not supported
####    | assign_oper
    | cast_oper
    | control_flow_func
    | str_func
    | date_func 
    | encrypt_func 
    | information_func
    | xml_func
    | misc_func
;

# TODO: provide reasonable IP for INET*

misc_func:
#### MDEV-10352 (crash)
####    DEFAULT( my_field )
#### Not supported
####    | GET_LOCK( arg , zero_or_almost )
#### TODO: Do not forget to restore |
      INET_ATON( arg )
    | INET_NTOA( arg )
#### Not supported
####    | IS_FREE_LOCK( arg )
#### Not supported
####    | IS_USED_LOCK( arg )
#### Not supported
####    | MASTER_POS_WAIT( 'log', _int_unsigned, zero_or_almost )
#### Not supported
####    | NAME_CONST( value, value )
    | RAND()
    | RAND( arg )
#### Not supported
####    | RELEASE_LOCK( arg )
#### Not supported
####    | SLEEP( zero_or_almost )
    | UUID_SHORT()
    | UUID()
#### Not supported
####   | VALUES( my_field )
;    

zero_or_almost:
    0 | 0.01 ;

xml_func:
      ExtractValue( value, xpath )
    | UpdateXML( value, xpath, value )
;

xpath:
#    { @chars = ('/','a','b','c','d','e'); $length = int(rand(128)); $xpath = ''; while (not $xpath) { foreach ( 1..$length ) { $xpath .= $chars[int(rand(scalar(@chars)))] }; $xpath =~ s/\/\///g; $xpath =~ s/\/$//g; }; "'".$xpath."'" } ;
    'abc';

information_func:
    CHARSET( arg )
#### Not supported
####    | BENCHMARK( _digit, select_item )
    | COERCIBILITY( arg )
    | COLLATION( arg )
    | CONNECTION_ID()
#### Not supported
####    | CURRENT_USER()
####    | CURRENT_USER
    | DATABASE() 
    | SCHEMA()
#### Not supported
####    | FOUND_ROWS()
#### Not supported
####    | LAST_INSERT_ID()
#### Not supported
####    | ROW_COUNT()
    | SESSION_USER() 
    | SYSTEM_USER() 
    | USER() 
    | /* Fails due to MDEV-10353 */ VERSION()
;    

control_flow_func:
     CASE arg WHEN arg THEN arg END 
   | CASE arg WHEN arg THEN arg WHEN arg THEN arg END 
   | CASE arg WHEN arg THEN arg ELSE arg END
   | IF( arg, arg, arg )
   | IFNULL( arg, arg )
   | NULLIF( arg, arg )
;

cast_oper:
     BINARY arg 
   | CAST( arg AS type ) 
   | CONVERT( arg, type ) 
   | CONVERT( arg USING charset ) 
;

charset:
   utf8 | latin1 ;

type:
     BINARY 
   | BINARY(_digit) 
   | CHAR 
   | CHAR(_digit) 
   | DATE 
   | DATETIME 
   | DECIMAL { $max_length = 65; $max_scale = 38; '' }  length_opt_decimal_opt 
   | SIGNED 
   | TIME 
   | UNSIGNED
;

encrypt_func:
     AES_DECRYPT( arg, arg ) 
   | AES_ENCRYPT( arg, arg )
   | COMPRESS( arg )
   | DECODE( arg, arg )
   | DES_DECRYPT( arg ) 
   | DES_DECRYPT( arg, arg )
   | DES_ENCRYPT( arg )
   | DES_ENCRYPT( arg, arg )
   | ENCODE( arg, arg )
   | ENCRYPT( arg ) 
   | ENCRYPT( arg, arg )
   | MD5( arg )
   | OLD_PASSWORD( arg ) 
   | PASSWORD( arg )
   | SHA1( arg )
   | SHA( arg )
   | SHA2( arg, arg )
   | UNCOMPRESS( arg )
   | UNCOMPRESSED_LENGTH( arg ) 
;

str_func:
     ASCII( arg )
   | BIN( arg )
   | BIT_LENGTH( arg )
   | CHAR_LENGTH( arg ) 
   | CHARACTER_LENGTH( arg )
   | CHAR( arg ) 
   | CHAR( arg USING charset )
   | CONCAT_WS( arg_list )
   | CONCAT( arg ) 
   | CONCAT( arg_list )
   | ELT( arg_list )
   | EXPORT_SET( arg, arg, arg ) 
   | EXPORT_SET( arg, arg, arg, arg ) 
   | EXPORT_SET( arg, arg, arg, arg, arg )
   | FIELD( arg_list )
   | FIND_IN_SET( arg, arg )
   | FORMAT( arg, arg ) 
   | FORMAT( arg, arg, locale )
   | HEX( arg )
   | INSERT( arg, arg, arg, arg )
   | INSTR( arg, arg )
   | LCASE( arg )
   | LEFT( arg, arg )
   | LENGTH( arg )
   | arg not LIKE arg
#### Not supported
####   | LOAD_FILE( arg )
   | LOCATE( arg, arg ) 
   | LOCATE( arg, arg, arg )
   | LOWER( arg )
   | LPAD( arg, arg, arg )
   | LTRIM( arg )
   | MAKE_SET( arg_list )
#### Not supported
####   | MATCH( field_list ) AGAINST ( arg search_modifier )
   | MID( arg, arg, arg )
   | OCT( arg )
   | OCTET_LENGTH( arg )
   | ORD( arg )
   | POSITION( arg IN arg )
   | QUOTE( arg )
# TODO: provide reasonable patterns to REGEXP
   | arg not REGEXP arg 
   | arg not RLIKE arg
   | REPEAT( arg, arg )
   | REPLACE( arg, arg, arg )
   | REVERSE( arg )
   | RIGHT( arg, arg )
   | RPAD( arg, arg, arg )
   | RTRIM( arg )
   | SOUNDEX( arg )
   | arg SOUNDS LIKE arg
   | SPACE( arg )
   | SUBSTR( arg, arg ) 
   | SUBSTR( arg FROM arg ) 
   | SUBSTR( arg, arg, arg ) 
   | SUBSTR( arg FROM arg FOR arg )
   | SUBSTRING_INDEX( arg, arg, arg )
   | TRIM( arg ) 
   | TRIM( trim_mode FROM arg ) 
   | TRIM( trim_mode arg FROM arg ) 
   | TRIM( arg FROM arg )
   | UCASE( arg )
   | UNHEX( arg )
   | UPPER( arg ) 
;

trim_mode:
     BOTH 
   | LEADING 
   | TRAILING 
;

search_modifier:
    | IN NATURAL LANGUAGE MODE 
    | IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION
    | IN BOOLEAN MODE
    | WITH QUERY EXPANSION 
;

date_func:
     ADDDATE( arg, INTERVAL arg unit1 ) 
   | ADDDATE( arg, arg )
   | ADDTIME( arg, arg )
   | CONVERT_TZ( arg, arg, arg )
   | CURDATE() | CURRENT_DATE() 
   | CURRENT_DATE
   | CURTIME() 
   | CURRENT_TIME() 
   | CURRENT_TIME 
   | CURRENT_TIMESTAMP() 
   | CURRENT_TIMESTAMP
   | DATE( arg )
   | DATEDIFF( arg, arg )
   | DATE_ADD( arg, INTERVAL arg unit1 ) | DATE_SUB( arg, INTERVAL arg unit1 )
   | /* Fails due to MDEV-10353 */ DATE_FORMAT( arg, arg )
   | DAY( arg ) | DAYOFMONTH( arg )
   | /* Fails due to MDEV-10353 */ DAYNAME( arg )
   | DAYOFWEEK( arg )
   | DAYOFYEAR( arg )
   | EXTRACT( unit1 FROM arg )
   | FROM_DAYS( arg )
   | FROM_UNIXTIME( arg ) | FROM_UNIXTIME( arg, arg )
   | GET_FORMAT( get_format_type, get_format_format )
   | HOUR( arg )
   | LAST_DAY( arg )
   | LOCALTIME()
   | LOCALTIMESTAMP()
   | MAKEDATE( arg, arg )
   | MAKETIME( arg, arg, arg )
   | MICROSECOND( arg )
   | MINUTE( arg )
   | MONTH( arg )
   | /* Fails due to MDEV-10353 */ MONTHNAME( arg )
   | NOW()
   | PERIOD_ADD( arg, arg )
   | PERIOD_DIFF( arg, arg )
   | QUARTER( arg )
   | SECOND( arg )
   | SEC_TO_TIME( arg )
   | STR_TO_DATE( arg, arg )
   | SUBDATE( arg, arg )
   | SUBTIME( arg, arg )
   | SYSDATE()
   | TIME( arg )
   | TIMEDIFF( arg, arg )
   | TIMESTAMP( arg ) | TIMESTAMP( arg, arg )
   | TIMESTAMPADD( unit2, arg, arg )
   | TIMESTAMPDIFF( unit2, arg, arg )
   | /* Fails due to MDEV-10353 */ TIME_FORMAT( arg, arg )
   | TIME_TO_SEC( arg )
   | TO_DAYS( arg )
   | TO_SECONDS( arg )
   | UNIX_TIMESTAMP( arg ) | UNIX_TIMESTAMP()
   | UTC_DATE()
   | UTC_TIME()
   | UTC_TIMESTAMP()
   | WEEK( arg ) 
   | WEEK( arg, week_mode )
   | WEEKDAY( arg )
   | WEEKOFYEAR( arg )
   | YEAR( arg )
   | YEARWEEK( arg ) 
   | YEARWEEK( arg, week_mode ) 
;

week_mode:
   0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | arg ;

get_format_type:
   DATE | TIME | DATETIME ;

get_format_format:
   'EUR' | 'USA' | 'JIS' | 'ISO' | 'INTERNAL' | arg ;

unit1:
     MICROSECOND
   | SECOND
   | MINUTE
   | HOUR
   | DAY 
   | WEEK
   | MONTH
   | QUARTER
   | YEAR
   | SECOND_MICROSECOND
   | MINUTE_MICROSECOND
   | MINUTE_SECOND
   | HOUR_MICROSECOND
   | HOUR_SECOND
   | HOUR_MINUTE
   | DAY_MICROSECOND
   | DAY_SECOND
   | DAY_MINUTE
   | DAY_HOUR
   | YEAR_MONTH 
;

unit2:
     MICROSECOND
   | SECOND
   | MINUTE
   | HOUR
   | DAY
   | WEEK
   | MONTH 
   | QUARTER
   | YEAR
;

math_func:
     ABS( arg ) 
   | ACOS( arg ) 
   | ASIN( arg ) 
   | ATAN( arg ) 
   | ATAN( arg, arg ) 
   | ATAN2( arg, arg )
   | CEIL( arg ) 
   | CEILING( arg ) 
   | CONV( arg, _tinyint_unsigned, _tinyint_unsigned ) 
   | COS( arg ) 
   | COT( arg ) 
   | CRC32( arg )
   | DEGREES( arg )
   | EXP( arg )
   | FLOOR( arg )
   | FORMAT( arg, _digit ) 
   | FORMAT( arg, format_second_arg, locale )
   | HEX( arg ) 
   | LN( arg ) 
   | LOG( arg ) 
   | LOG( arg, arg ) 
   | LOG2( arg ) 
   | LOG10( arg )
   | MOD( arg, arg ) 
   | PI( ) 
   | POW( arg, arg ) 
   | POWER( arg, arg )
   | RADIANS( arg ) 
   | RAND() 
   | RAND( arg ) 
   | ROUND( arg ) 
   | ROUND( arg, arg )
   | SIGN( arg ) 
   | SIN( arg ) 
   | SQRT( arg )
   | TAN( arg ) 
   | TRUNCATE( arg, truncate_second_arg ) 
;

arithm_oper:
     arg + arg 
   | arg - arg
   | - arg
   | arg * arg
   | arg / arg
   | arg DIV arg 
   | arg MOD arg
   | arg % arg 
;

logical_or_bitwise_oper:
     NOT arg 
   | ! arg 
   | ~ arg
   | arg AND arg 
   | arg && arg 
   | arg & arg 
   | arg OR arg 
   | arg 
   | arg 
   | arg XOR arg 
   | arg ^ arg
   | arg << arg 
   | arg >> arg 
;

assign_oper:
   @A := arg ;
   
comparison_oper:
     arg = arg
   | arg <=> arg
   | arg != arg
   | arg <> arg
   | arg <= arg
   | arg < arg
   | arg >= arg
   | arg > arg
   | arg IS not bool_value
   | arg not BETWEEN arg AND arg
   | COALESCE( arg_list )
   | GREATEST( arg_list )
   | arg not IN ( arg_list )
   | ISNULL( arg )
   | INTERVAL( arg_list )
   | LEAST( arg_list )
   | arg not LIKE arg
   | STRCMP( arg, arg )
; 

not:
    | NOT ;

arg_list:
     arg_list_2 
   | arg_list_3 
   | arg_list_5 
   | arg_list_10 
   | arg, arg_list 
;

arg_list_2:
   arg, arg ;

arg_list_3:
   arg, arg, arg ;

arg_list_5:
   arg, arg, arg, arg, arg ;

arg_list_10:
   arg, arg, arg, arg, arg, arg, arg, arg, arg, arg ;


field_list:
      my_field 
    | field_list , my_field 
;

format_second_arg:
   truncate_second_arg ;

truncate_second_arg:
     _digit 
   | _digit 
   | _tinyint_unsigned 
   | arg
;

arg:
     my_field 
   | value 
   | ( func )
;
   
my_field:
    { 'col' . int(rand($ncol))+1 };

value:
     _bigint 
   | _smallint 
   | _int_usigned 
   | _char(1) 
   | _char(256) 
   | _datetime 
   | _date 
   | _time 
   | NULL 
;

bool_value:
     TRUE 
   | FALSE 
   | UNKNOWN 
   | NULL 
;

locale:
     'en_US' 
   | 'de_DE' 
;

