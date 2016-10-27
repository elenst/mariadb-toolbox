# MDEV-9872 Add common optimized CRC32 function interface
#
# The grammar focuses on CRC32 function. 
# It can be used on a single server for crash testing, 
# or on two servers for result comparison.
# Functions which prevent valid comparison have been removed.

query_init:
    { $tmp_table = 0; '' } ;

query:
      SELECT CRC32( ( select_one ) )
    | select ;

select_one:
   { $num = 0; '' } SELECT distinct select_item AS { $num++; 'field'.$num } FROM _table where order_by_limit;

select:
   { $num = 0; '' } SELECT distinct select_list FROM _table where order_by_limit;

select_list:
   select_item AS { $num++; 'field'.$num } | select_item AS { $num++; 'field'.$num } , select_list ;

distinct:
   | DISTINCT ; 

select_item:
   func | aggregate_func | CRC32(select_item)
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

order_by_limit:
   | ORDER BY func limit | ORDER BY func, func LIMIT limit ;

limit:
   1 | 1 | 1 | 1 | 1 | 1 | 0 ;

func:
    math_func | 
    arithm_oper | 
    comparison_oper | 
    logical_or_bitwise_oper | 
    assign_oper | 
    cast_oper | 
    control_flow_func | 
    str_func | 
    date_func | 
    encrypt_func | 
    information_func |
    misc_func
;

misc_func:
    DEFAULT( _field ) |
    INET_ATON( arg ) |
    INET_NTOA( arg ) |
    MASTER_POS_WAIT( 'log', _int_unsigned, zero_or_almost ) |
    RAND( arg ) |
    SLEEP( zero_or_almost ) |
    VALUES( _field )
;    

zero_or_almost:
    0 | 0.01 ;

information_func:
    CHARSET( arg ) |
    COERCIBILITY( arg ) |
    COLLATION( arg ) |
    CURRENT_USER() | CURRENT_USER |
    DATABASE() | SCHEMA() |
    FOUND_ROWS() |
    LAST_INSERT_ID() |
    ROW_COUNT() |
    SESSION_USER() | SYSTEM_USER() | USER() 
;    

control_flow_func:
   CASE arg WHEN arg THEN arg END | CASE arg WHEN arg THEN arg WHEN arg THEN arg END | CASE arg WHEN arg THEN arg ELSE arg END |
   IF( arg, arg, arg ) |
   IFNULL( arg, arg ) |
   NULLIF( arg, arg )
;

cast_oper:
   BINARY arg | CAST( arg AS type ) | CONVERT( arg, type ) | CONVERT( arg USING charset ) ;

charset:
   utf8 | latin1 ;

type:
   BINARY | BINARY(_digit) | CHAR | CHAR(_digit) | DATE | DATETIME | DECIMAL | DECIMAL(decimal_m) | DECIMAL(decimal_m,decimal_d) | SIGNED | TIME | UNSIGNED ;

decimal_m:
    { $decimal_m = $prng->int(0,65) } 

decimal_d:
    { $decimal_d = $prng->int(0,$decimal_m) } 

encrypt_func:
   AES_DECRYPT( arg, arg ) |
   AES_ENCRYPT( arg, arg ) |
   COMPRESS( arg ) |
   DECODE( arg, arg ) |
   DES_DECRYPT( arg ) | DES_DECRYPT( arg, arg ) |
   DES_ENCRYPT( arg ) | DES_ENCRYPT( arg, arg ) |
   ENCODE( arg, arg ) |
   ENCRYPT( arg ) | ENCRYPT( arg, arg ) |
   MD5( arg ) |
   OLD_PASSWORD( arg ) | 
   PASSWORD( arg ) |
   SHA1( arg ) |
   SHA( arg ) |
   SHA2( arg, arg ) |
   UNCOMPRESS( arg ) |
   UNCOMPRESSED_LENGTH( arg ) 
;

str_func:
   ASCII( arg ) |
   BIN( arg ) |
   BIT_LENGTH( arg ) |
   CHAR_LENGTH( arg ) | CHARACTER_LENGTH( arg ) | 
   CHAR( arg ) | CHAR( arg USING charset ) |
   CONCAT_WS( arg_list ) | 
   CONCAT( arg ) | CONCAT( arg_list ) |
   ELT( arg_list ) |
   EXPORT_SET( arg, arg, arg ) | EXPORT_SET( arg, arg, arg, arg ) | EXPORT_SET( arg, arg, arg, arg, arg ) |
   FIELD( arg_list ) |
   FIND_IN_SET( arg, arg ) |
   FORMAT( arg, arg ) | FORMAT( arg, arg, locale ) |
   HEX( arg ) |
   INSERT( arg, arg, arg, arg ) |
   INSTR( arg, arg ) |
   LCASE( arg ) |
   LEFT( arg, arg ) |
   LENGTH( arg ) |
    arg not LIKE arg |
   LOAD_FILE( arg ) |
   LOCATE( arg, arg ) | LOCATE( arg, arg, arg ) |
   LOWER( arg ) |
   LPAD( arg, arg, arg ) |
   LTRIM( arg ) |
   MAKE_SET( arg_list ) |
   MID( arg, arg, arg ) |
   OCT( arg ) |
   OCTET_LENGTH( arg ) |
   ORD( arg ) |
   POSITION( arg IN arg ) |
   QUOTE( arg ) |
   arg not REGEXP arg | arg not RLIKE arg |
   REPEAT( arg, arg ) |
   REPLACE( arg, arg, arg ) |
   REVERSE( arg ) |
   RIGHT( arg, arg ) |
   RPAD( arg, arg, arg ) |
   RTRIM( arg ) |
   SOUNDEX( arg ) |
   arg SOUNDS LIKE arg |
   SPACE( arg ) |
   SUBSTR( arg, arg ) | SUBSTR( arg FROM arg ) | SUBSTR( arg, arg, arg ) | SUBSTR( arg FROM arg FOR arg ) |
   SUBSTRING_INDEX( arg, arg, arg ) |
   TRIM( arg ) | TRIM( trim_mode FROM arg ) | TRIM( trim_mode arg FROM arg ) | TRIM( arg FROM arg ) |
   UCASE( arg ) |
   UNHEX( arg ) |
   UPPER( arg ) 
;

trim_mode:
   BOTH | LEADING | TRAILING ;

search_modifier:
    |
    IN NATURAL LANGUAGE MODE |
    IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION |
    IN BOOLEAN MODE |
    WITH QUERY EXPANSION 
;

date_func:
   ADDDATE( arg, INTERVAL arg unit1 ) | ADDDATE( arg, arg ) |
   ADDTIME( arg, arg ) | 
   CONVERT_TZ( arg, arg, arg ) |
   DATE( arg ) |
   DATEDIFF( arg, arg ) |
   DATE_ADD( arg, INTERVAL arg unit1 ) | DATE_SUB( arg, INTERVAL arg unit1 ) |
   DATE_FORMAT( arg, arg ) |
   DAY( arg ) | DAYOFMONTH( arg ) | 
   DAYNAME( arg ) |
   DAYOFWEEK( arg ) |
   DAYOFYEAR( arg ) | 
   EXTRACT( unit1 FROM arg ) |
   FROM_DAYS( arg ) |
   FROM_UNIXTIME( arg ) | FROM_UNIXTIME( arg, arg ) |
   GET_FORMAT( get_format_type, get_format_format ) |
   HOUR( arg ) |
   LAST_DAY( arg ) |
   MAKEDATE( arg, arg ) |
   MAKETIME( arg, arg, arg ) |
   MICROSECOND( arg ) |
   MINUTE( arg ) |
   MONTH( arg ) |
   MONTHNAME( arg ) |
   PERIOD_ADD( arg, arg ) |
   PERIOD_DIFF( arg, arg ) |
   QUARTER( arg ) |
   SECOND( arg ) |
   SEC_TO_TIME( arg ) |
   STR_TO_DATE( arg, arg ) |
   SUBDATE( arg, arg ) |
   SUBTIME( arg, arg ) |
   TIME( arg ) |
   TIMEDIFF( arg, arg ) |
   TIMESTAMP( arg ) | TIMESTAMP( arg, arg ) |
   TIMESTAMPADD( unit2, arg, arg ) |
   TIMESTAMPDIFF( unit2, arg, arg ) |
   TIME_FORMAT( arg, arg ) |
   TIME_TO_SEC( arg ) |
   TO_DAYS( arg ) |
   TO_SECONDS( arg ) |
   UNIX_TIMESTAMP( arg ) | UNIX_TIMESTAMP() |
   WEEK( arg ) | WEEK( arg, week_mode ) |
   WEEKDAY( arg ) |
   WEEKOFYEAR( arg ) |
   YEAR( arg ) |
   YEARWEEK( arg ) | YEARWEEK( arg, week_mode ) 
;

week_mode:
   0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | arg ;

get_format_type:
   DATE | TIME | DATETIME ;

get_format_format:
   'EUR' | 'USA' | 'JIS' | 'ISO' | 'INTERNAL' | arg ;

unit1:
   MICROSECOND |
   SECOND |
   MINUTE |
   HOUR |
   DAY | 
   WEEK |
   MONTH |
   QUARTER |
   YEAR |
   SECOND_MICROSECOND |
   MINUTE_MICROSECOND |
   MINUTE_SECOND |
   HOUR_MICROSECOND |
   HOUR_SECOND |
   HOUR_MINUTE |
   DAY_MICROSECOND |
   DAY_SECOND |
   DAY_MINUTE |
   DAY_HOUR |
   YEAR_MONTH 
;

unit2:
   MICROSECOND |
   SECOND |
   MINUTE |
   HOUR |
   DAY |
   WEEK |
   MONTH | 
   QUARTER |
   YEAR
;

math_func:
   ABS( arg ) | ACOS( arg ) | ASIN( arg ) | ATAN( arg ) | ATAN( arg, arg ) | ATAN2( arg, arg ) |
   CEIL( arg ) | CEILING( arg ) | CONV( arg, _tinyint_unsigned, _tinyint_unsigned ) | COS( arg ) | COT( arg ) | CRC32( arg ) |
   DEGREES( arg ) | 
   EXP( arg ) | 
   FLOOR( arg ) | 
   FORMAT( arg, _digit ) | FORMAT( arg, format_second_arg, locale ) | 
   HEX( arg ) | 
   LN( arg ) | LOG( arg ) | LOG( arg, arg ) | LOG2( arg ) | LOG10( arg ) |
   MOD( arg, arg ) | 
   PI( ) | POW( arg, arg ) | POWER( arg, arg ) |
   RADIANS( arg ) | 
   RAND( arg ) | 
   ROUND( arg ) | ROUND( arg, arg ) | 
   SIGN( arg ) | SIN( arg ) | SQRT( arg ) | 
   TAN( arg ) | TRUNCATE( arg, truncate_second_arg ) ;

arithm_oper:
   arg + arg | 
   arg - arg | 
   - arg |
   arg * arg |
   arg / arg |
   arg DIV arg | 
   arg MOD arg |
   arg % arg 
;

logical_or_bitwise_oper:
   NOT arg | ! arg | ~ arg |
   arg AND arg | arg && arg | arg & arg |
   arg OR arg | arg | arg |
   arg XOR arg | arg ^ arg |
    arg << arg | arg >> arg 
;

assign_oper:
   @A := arg ;
   
comparison_oper:
   arg = arg |
   arg <=> arg |
   arg != arg |
   arg <> arg |
   arg <= arg |
   arg < arg |
   arg >= arg |
   arg > arg |
   arg IS not bool_value |
   arg not BETWEEN arg AND arg |
   COALESCE( arg_list ) |
   GREATEST( arg_list ) |
   arg not IN ( arg_list ) |
   ISNULL( arg ) | 
   INTERVAL( arg_list ) |
   LEAST( arg_list ) |
    arg not LIKE arg |
    STRCMP( arg, arg )
; 

not:
    | NOT ;

arg_list:
   arg_list_2 | arg_list_3 | arg_list_5 | arg_list_10 | arg, arg_list ;

arg_list_2:
   arg, arg ;

arg_list_3:
   arg, arg, arg ;

arg_list_5:
   arg, arg, arg, arg, arg ;

arg_list_10:
   arg, arg, arg, arg, arg, arg, arg, arg, arg, arg ;


field_list:
    _field | field_list , _field ;

format_second_arg:
   truncate_second_arg ;

truncate_second_arg:
   _digit | _digit | _tinyint_unsigned | arg ;

arg:
   _field | value | ( func ) ;

value:
   _bigint | _smallint | _int_usigned | _char(1) | _char(256) | _datetime | _date | _time | NULL ;

bool_value:
   TRUE | FALSE | UNKNOWN | NULL ;

locale:
   'en_US' | 'de_DE' ;

