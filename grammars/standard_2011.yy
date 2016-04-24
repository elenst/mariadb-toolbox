# RQG part:
query_init:
    { $query_count = 0; '' };

query:
    query_specification /* QUERY NO { ++$query_count } */;


###############################################################################
###############################################################################
# Standard part


sql_terminal_character:
 sql_language_character
 ;

sql_language_character:
 simple_latin_letter | digit | sql_special_character
 ;

simple_latin_letter:
 simple_latin_upper_case_letter | simple_latin_lower_case_letter
 ;

simple_latin_upper_case_letter:
 A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z
 ;

simple_latin_lower_case_letter:
 a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z
 ;

digit:
 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
 ;

sql_special_character:
 space | " | % | & | ' | ( | ) | * | + | , | - | .
 ;

# Modified
space:
 # see the syntax rules.
 { $a = ' ' }
 ;

percent:
 %
 ;

&:
 &
 ;

quote:
 '
 ;

asterisk:
 *
 ;

+:
 +
 ;

comma:
 ,
 ;

-:
 -
 ;

period:
 .
 ;

solidus:
 /
 ;

reverse_solidus:
 \
 ;

colon:
 :
 ;

semicolon:
 ;
 ;

less_than_operator:
 
 ;

equals_operator:
 =
 ;

greater_than_operator:
 
 ;

question_mark:
 ?
 ;

left_bracket_or_trigraph:
   [ 
# Not supported
# | left_bracket_trigraph
 ;

right_bracket_or_trigraph:
   ]
# Not supported
# | right_bracket_trigraph
 ;

left_bracket:
 [
 ;

# Not supported
left_bracket_trigraph:
 ??(
 ;

right_bracket:
 ]
 ;

# Not supported
right_bracket_trigraph:
 ??)
 ;

circumflex:
 ^
 ;

underscore:
 _
 ;

vertical_bar:
 |
 ;

left_brace:
 {
 ;

right_brace:
 }
 ;

token:
 nondelimiter_token | delimiter_token
 ;

nondelimiter_token:
   regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | key_word 
 | unsigned_numeric_literal
 | national_character_string_literal
 | binary_string_literal
 | large_object_length_token
# Not supported
# | unicode_delimited_identifier
# Not supported
# | unicode_character_string_literal
 | sql_language_identifier
 ;

regular_identifier:
 identifier_body
 ;

# Modified
# Heavily modified
identifier_body:
# identifier_start [ identifier_part... ]
# identifier_start _maybe_identifier_parts
 { $field_length = int(rand(64)); $prng->string($field_length) }
 ;

# Added
# Modified probabilities
_maybe_identifier_parts:
 | | | | | |
 identifier_part _maybe_identifier_parts
 ;
 
identifier_part:
   identifier_start 
 | identifier_start 
 | identifier_start 
 | identifier_extend
 ;

# Heavily modified
# TODO:
# An <identifier start> is any character in the Unicode General Category classes “Lu”, “Ll”, “Lt”, “Lm”, “Lo”, or “Nl”.
identifier_start:
 simple_latin_letter 
 ;

# TODO
identifier_extend:
 # see the syntax rules.
 ;

# Modified
# Heavily modified
large_object_length_token:
# digit... multiplier
# _digit_multi multiplier
  { @multipliers = qw(K M G T P); int(rand(2147483647)).$multipliers[int(rand(scalar @multipliers))] } 
 ;

# Added
# Heavily modified
_digit_multi:
# digit | digit _digit_multi
 { int(rand(18446744073709551616)) }
 ;
 
multiplier:
 K | M | G | T | P
 ;

# Heavily modified
# Not supported
delimited_identifier:
# " delimited_identifier_body "
 { $field_length = int(rand(64)); '"'.$prng->string($field_length).'"' }
 ;

# Modified
delimited_identifier_body:
# delimited_identifier_part...
 _delimited_identifier_part_multi
 ;
 
# Added
_delimited_identifier_part_multi:
   delimited_identifier_part
 | delimited_identifier_part
 | delimited_identifier_part
 | delimited_identifier_part
 | delimited_identifier_part _delimited_identifier_part_multi
 ;

delimited_identifier_part:
 nondoublequote_character | ""
 ;

# Heavily modified
# Not supported (works in PostreSQL)
unicode_delimited_identifier:
# U&" unicode_delimiter_body " unicode_escape_specifier
 { $field_length = int(rand(64)); 'U&"'.$prng->string($field_length).'"' }
 ;

# Modified
unicode_escape_specifier:
# [ uescape quote unicode_escape_character quote ]
 _maybe_uescape_quote_unicode_escape_character_quote
 ;
 
# Added
# Modified probabilities
_maybe_uescape_quote_unicode_escape_character_quote:
 | | | | |
 UESCAPE ' unicode_escape_character '
 ;

# Modified
unicode_delimiter_body:
# unicode_identifier_part...
 _unicode_identifier_parts
 ;
 
# Added
_unicode_identifier_parts:
 unicode_identifier_part | unicode_identifier_part _unicode_identifier_parts
 ;

unicode_identifier_part:
 delimited_identifier_part | unicode_escape_value
 ;

unicode_escape_value:
 unicode_4_digit_escape_value | unicode_6_digit_escape_value | unicode_character_escape_value
 ;

unicode_4_digit_escape_value:
 unicode_escape_character hexit hexit hexit hexit
 ;

unicode_6_digit_escape_value:
 unicode_escape_character + hexit hexit hexit hexit hexit hexit
 ;

unicode_character_escape_value:
 unicode_escape_character unicode_escape_character
 ;

# TODO:
# Unicode escape character> shall be a single character from the source language character set other than a <hexit>, <plus sign>, <quote>, <double quote>, or <white space>.
unicode_escape_character:
 \
 ;

nondoublequote_character:
 # see the syntax rules.
 ;

doublequote_symbol:
 ""
 # two consecutive double quote characters
 ;

delimiter_token:
 character_string_literal | date_string | time_string | timestamp_string | interval_string | delimited_identifier | sql_special_character | not_equals_operator | greater_than_or_equals_operator | less_than_or_equals_operator | concatenation_operator
 ;

not_equals_operator:
 <>
 ;

greater_than_or_equals_operator:
 >=
 ;

less_than_or_equals_operator:
 <=
 ;

concatenation_operator:
 ||
 ;

right_arrow:
 ->
 ;

double_colon:
 ::
 ;

double_period:
 ..
 ;

named_argument_assignment_token:
 =>
 ;

# Modified
separator:
# { comment | white_space }...
 _comment_or_white_space_multi
 ;
 
# Added
_comment_or_white_space_multi:
   _comment_or_white_space
 | _comment_or_white_space
 | _comment_or_white_space
 | _comment_or_white_space
 | _comment_or_white_space _comment_or_white_space_multi
 ;
 
# Added
_comment_or_white_space:
 comment | white_space
 ;

# TODO
# Heavily modified
white_space:
 # see the syntax rules.
 { $a = ' ' }
 ;

comment:
 simple_comment | bracketed_comment
 ;

# Modified
simple_comment:
# simple_comment_introducer [ comment_character... ] newline
 simple_comment_introducer _maybe_comment_characters newline
 ;

# Added
# Modified probabilities
_maybe_comment_characters:
 | | | | |
 comment_character _maybe_comment_characters
 ;
 
simple_comment_introducer:
 --
 ;

bracketed_comment:
 bracketed_comment_introducer bracketed_comment_contents bracketed_comment_terminator
 ;

bracketed_comment_introducer:
 /*
 ;

bracketed_comment_terminator:
 */
 ;

# Modified
bracketed_comment_contents:
# [ { comment_character | separator }... ]
 # see the syntax rules.
 _maybe_comment_characters_or_separators
 ;

# Added
_maybe_comment_characters_or_separators:
 | _comment_character_or_separator _maybe_comment_characters_or_separators
 ;
  
# Added
_comment_character_or_separator:
 comment_character | separator 
 ;
 
comment_character:
 nonquote_character | '
 ;

# TODO
# Modified
newline:
 # see the syntax rules.
 { "\n" }
 ;

key_word:
 reserved_word | non_reserved_word
 ;

non_reserved_word:
 A | ABSOLUTE | ACTION | ADA | ADD | ADMIN | AFTER | ALWAYS | ASC | ASSERTION | ASSIGNMENT | ATTRIBUTE | ATTRIBUTES
| BEFORE | BERNOULLI | BREADTH
| C | CASCADE | CATALOG | CATALOG_NAME | CHAIN | CHARACTER_SET_CATALOG | CHARACTER_SET_NAME | CHARACTER_SET_SCHEMA | CHARACTERISTICS | CHARACTERS | CLASS_ORIGIN | COBOL | COLLATION | COLLATION_CATALOG | COLLATION_NAME | COLLATION_SCHEMA | COLUMN_NAME | COMMAND_FUNCTION | COMMAND_FUNCTION_CODE | COMMITTED | CONDITION_NUMBER | CONNECTION | CONNECTION_NAME | CONSTRAINT_CATALOG | CONSTRAINT_NAME | CONSTRAINT_SCHEMA | CONSTRAINTS | CONSTRUCTOR | CONTINUE | CURSOR_NAME
| DATA | DATETIME_INTERVAL_CODE | DATETIME_INTERVAL_PRECISION | DEFAULTS | DEFERRABLE | DEFERRED | DEFINED | DEFINER | DEGREE | DEPTH | DERIVED | DESC | DESCRIPTOR | DIAGNOSTICS | DISPATCH | DOMAIN | DYNAMIC_FUNCTION | DYNAMIC_FUNCTION_CODE
| ENFORCED | EXCLUDE | EXCLUDING | EXPRESSION
| FINAL | FIRST | FLAG | FOLLOWING | FORTRAN | FOUND
| G | GENERAL | GENERATED | GO | GOTO | GRANTED
| HIERARCHY
| IGNORE | IMMEDIATE | IMMEDIATELY | IMPLEMENTATION | INCLUDING | INCREMENT | INITIALLY | INPUT | INSTANCE | INSTANTIABLE | INSTEAD | INVOKER | ISOLATION
| K | KEY | KEY_MEMBER | KEY_TYPE
| LAST | LENGTH | LEVEL | LOCATOR
| M | MAP | MATCHED | MAXVALUE | MESSAGE_LENGTH | MESSAGE_OCTET_LENGTH | MESSAGE_TEXT | MINVALUE | MORE | MUMPS
| NAME | NAMES | NESTING | NEXT | NFC | NFD | NFKC | NFKD | NORMALIZED | NULLABLE | NULLS | NUMBER
| OBJECT | OCTETS | OPTION | OPTIONS | ORDERING | ORDINALITY | OTHERS | OUTPUT | OVERRIDING
| P | PAD | PARAMETER_MODE | PARAMETER_NAME | PARAMETER_ORDINAL_POSITION | PARAMETER_SPECIFIC_CATALOG | PARAMETER_SPECIFIC_NAME | PARAMETER_SPECIFIC_SCHEMA | PARTIAL | PASCAL | PATH | PLACING | PLI | PRECEDING | PRESERVE | PRIOR | PRIVILEGES | PUBLIC
| READ | RELATIVE | REPEATABLE | RESPECT | RESTART | RESTRICT | RETURNED_CARDINALITY | RETURNED_LENGTH | RETURNED_OCTET_LENGTH | RETURNED_SQLSTATE | ROLE | ROUTINE | ROUTINE_CATALOG | ROUTINE_NAME | ROUTINE_SCHEMA | ROW_COUNT
| SCALE | SCHEMA | SCHEMA_NAME | SCOPE_CATALOG | SCOPE_NAME | SCOPE_SCHEMA | SECTION | SECURITY | SELF | SEQUENCE | SERIALIZABLE | SERVER_NAME | SESSION | SETS | SIMPLE | SIZE | SOURCE | SPACE | SPECIFIC_NAME | STATE | STATEMENT | STRUCTURE | STYLE | SUBCLASS_ORIGIN
| T | TABLE_NAME | TEMPORARY | TIES | TOP_LEVEL_COUNT | TRANSACTION | TRANSACTION_ACTIVE | TRANSACTIONS_COMMITTED | TRANSACTIONS_ROLLED_BACK | TRANSFORM | TRANSFORMS | TRIGGER_CATALOG | TRIGGER_NAME | TRIGGER_SCHEMA | TYPE
| UNBOUNDED | UNCOMMITTED | UNDER | UNNAMED | USAGE | USER_DEFINED_TYPE_CATALOG | USER_DEFINED_TYPE_CODE | USER_DEFINED_TYPE_NAME | USER_DEFINED_TYPE_SCHEMA
| VIEW
| WORK | WRITE
| ZONE
 ;

reserved_word:
 ABS | ALL | ALLOCATE | ALTER | AND | ANY | ARE | ARRAY | ARRAY_AGG | ARRAY_MAX_CARDINALITY | AS | ASENSITIVE | ASYMMETRIC | AT | ATOMIC | AUTHORIZATION | AVG
 | ARRAY_MAX_CARDINALITY | AS | ASENSITIVE | ASYMMETRIC | AT | ATOMIC | AUTHORIZATION | AVG
| BEGIN | BEGIN_FRAME | BEGIN_PARTITION | BETWEEN | BIGINT | BINARY | BLOB | BOOLEAN | BOTH | BY
| CALL | CALLED | CARDINALITY | CASCADED | CASE | CAST | CEIL | CEILING | CHAR | CHAR_LENGTH | CHARACTER | CHARACTER_LENGTH | CHECK | CLOB | CLOSE | COALESCE | COLLATE | COLLECT | COLUMN | COMMIT | CONDITION | CONNECT | CONSTRAINT | CONTAINS | CONVERT | CORR | CORRESPONDING | COUNT | COVAR_POP | COVAR_SAMP | CREATE | CROSS | CUBE | CUME_DIST | CURRENT | CURRENT_CATALOG | CURRENT_DATE | CURRENT_DEFAULT_TRANSFORM_GROUP | CURRENT_PATH | CURRENT_ROLE | CURRENT_ROW | CURRENT_SCHEMA | CURRENT_TIME | CURRENT_TIMESTAMP | CURRENT_TRANSFORM_GROUP_FOR_TYPE | CURRENT_USER | CURSOR | CYCLE
| DATE | DAY | DEALLOCATE | DEC | DECIMAL | DECLARE | DEFAULT | DELETE | DENSE_RANK | DEREF | DESCRIBE | DETERMINISTIC | DISCONNECT | DISTINCT | DOUBLE | DROP | DYNAMIC
| EACH | ELEMENT | ELSE | END | END_FRAME | END_PARTITION | END-EXEC | EQUALS | ESCAPE | EVERY | EXCEPT | EXEC | EXECUTE | EXISTS | EXP | EXTERNAL | EXTRACT
| FALSE | FETCH | FILTER | FIRST_VALUE | FLOAT | FLOOR | FOR | FOREIGN | FRAME_ROW | FREE | FROM | FULL | FUNCTION | FUSION
| GET | GLOBAL | GRANT | GROUP | GROUPING | GROUPS
| HAVING | HOLD | HOUR
| IDENTITY | IN | INDICATOR | INNER | INOUT | INSENSITIVE | INSERT | INT | INTEGER | INTERSECT | INTERSECTION | INTERVAL | INTO | IS
| JOIN
| LAG | LANGUAGE | LARGE | LAST_VALUE | LATERAL | LEAD | LEADING | LEFT | LIKE | LIKE_REGEX | LN | LOCAL | LOCALTIME | LOCALTIMESTAMP | LOWER
| MATCH | MAX | MEMBER | MERGE | METHOD | MIN | MINUTE | MOD | MODIFIES | MODULE | MONTH | MULTISET
| NATIONAL | NATURAL | NCHAR | NCLOB | NEW | NO | NONE | NORMALIZE | NOT | NTH_VALUE | NTILE | NULL | NULLIF | NUMERIC
| OCTET_LENGTH | OCCURRENCES_REGEX | OF | OFFSET | OLD | ON | ONLY | OPEN | OR | ORDER | OUT | OUTER | OVER | OVERLAPS | OVERLAY
| PARAMETER | PARTITION | PERCENT | PERCENT_RANK | PERCENTILE_CONT | PERCENTILE_DISC | PERIOD | PORTION | POSITION | POSITION_REGEX | POWER | PRECEDES | PRECISION | PREPARE | PRIMARY | PROCEDURE
| RANGE | RANK | READS | REAL | RECURSIVE | REF | REFERENCES | REFERENCING | REGR_AVGX | REGR_AVGY | REGR_COUNT | REGR_INTERCEPT | REGR_R2 | REGR_SLOPE | REGR_SXX | REGR_SXY | REGR_SYY | RELEASE | RESULT | RETURN | RETURNS | REVOKE | RIGHT | ROLLBACK | ROLLUP | ROW | ROW_NUMBER | ROWS
| SAVEPOINT | SCOPE | SCROLL | SEARCH | SECOND | SELECT | SENSITIVE | SESSION_USER | SET | SIMILAR | SMALLINT | SOME | SPECIFIC | SPECIFICTYPE | SQL | SQLEXCEPTION | SQLSTATE | SQLWARNING | SQRT | START | STATIC | STDDEV_POP | STDDEV_SAMP | SUBMULTISET | SUBSTRING | SUBSTRING_REGEX | SUCCEEDS | SUM | SYMMETRIC | SYSTEM | SYSTEM_TIME | SYSTEM_USER
| TABLE | TABLESAMPLE | THEN | TIME | TIMESTAMP | TIMEZONE_HOUR | TIMEZONE_MINUTE | TO | TRAILING | TRANSLATE | TRANSLATE_REGEX | TRANSLATION | TREAT | TRIGGER | TRUNCATE | TRIM | TRIM_ARRAY | TRUE
| UESCAPE | UNION | UNIQUE | UNKNOWN | UNNEST | UPDATE | UPPER | USER | USING
| VALUE | VALUES | VALUE_OF | VAR_POP | VAR_SAMP | VARBINARY | VARCHAR | VARYING | VERSIONING
| WHEN | WHENEVER | WHERE | WIDTH_BUCKET | WINDOW | WITH | WITHIN | WITHOUT
| YEAR
 ;
 
literal:
 signed_numeric_literal | general_literal
 ;

unsigned_literal:
 unsigned_numeric_literal | general_literal
 ;

general_literal:
   character_string_literal
 | national_character_string_literal
# Not supported
# | unicode_character_string_literal
 | binary_string_literal
 | datetime_literal
 | interval_literal
 | boolean_literal
 ;

# Modified
character_string_literal:
# [ introducer character_set_specification ] quote [ character_representation... ] quote [ { separator quote [ character_representation... ] quote }... ]
 _maybe_introducer_and_character_set_specification ' _maybe_character_representations ' _maybe_separator_quote_maybe_character_representation_quote_multiple
 ;
 
# Added
_maybe_introducer_and_character_set_specification:
 | introducer character_set_specification
 ;
  
# Added
_maybe_character_representations:
 | character_representation _maybe_character_representations
 ;
 
# Added
_maybe_separator_quote_maybe_character_representation_quote_multiple:
 | separator ' _maybe_character_representations ' _maybe_separator_quote_maybe_character_representation_quote_multiple
 ;
 
introducer:
 underscore
 ;

character_representation:
 nonquote_character | quote_symbol
 ;

nonquote_character:
 # see the syntax rules.
 ;

quote_symbol:
 ' '
 ;

# Heavily modified
national_character_string_literal:
# n quote [ character_representation... ] quote [ { separator quote [ character_representation... ] quote }... ]
# N' _maybe_character_representations ' _maybe_separator_quote_maybe_character_representation_quote_multiple
 { $len=int(rand(32)); $str="N'"; foreach (1..$len) {$str.=chr(int(rand(256)))}; $str.="'" }
 ;

# Modified
# Not supported
unicode_character_string_literal:
# [ introducer character_set_specification ] u & quote [ unicode_representation... ] quote [ { separator quote [ unicode_representation... ] quote }... ] unicode_escape_specifier
 _maybe_introducer_and_character_set_specification U&' _maybe_unicode_representations ' _maybe_separator_quote_maybe_unicode_representation_quote_multiple unicode_escape_specifier
 ;
 
# Added
_maybe_unicode_representations:
 | unicode_representation _maybe_unicode_representations 
 ;
 
# Added
_maybe_separator_quote_maybe_unicode_representation_quote_multiple:
 | separator ' _maybe_unicode_representations ' _maybe_separator_quote_maybe_unicode_representation_quote_multiple
 ;
 
unicode_representation:
 character_representation | unicode_escape_value
 ;

# Heavily modified
binary_string_literal:
# x quote [ space... ] [ { hexit [ space... ] hexit [ space... ] }... ] quote [ { separator quote [ space... ] [ { hexit [ space... ] hexit [ space... ] }... ] quote }... ]
# X' _maybe_spaces _maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi ' _maybe_separator_quote_maybe_spaces_maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi_quote_multi
 { $len=int(rand(16)*2); @hx=qw(0 1 2 3 4 5 6 7 8 9 A B C D E F a b c d e f); $str="X'"; foreach (1..$len) {$str.=$hx[int(rand(scalar(@hx)))] }; $str.="'" }
 ;

# Added
_maybe_spaces:
 | | | | | |
 space _maybe_spaces ;

# Added
_maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi:
 | | | | | |
 hexit _maybe_spaces hexit _maybe_spaces _maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi
 ;
 
# Added
_maybe_separator_quote_maybe_spaces_maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi_quote_multi:
 | | | | | |
 separator ' _maybe_spaces _maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi ' _maybe_separator_quote_maybe_spaces_maybe_hexit_maybe_spaces_hexit_maybe_spaces_multi_quote_multi
 ;
 
hexit:
 digit | A | B | C | D | E | F | a | b | c | d | e | f
 ;

# Modified
signed_numeric_literal:
# [ sign ] unsigned_numeric_literal
 _maybe_sign unsigned_numeric_literal
 ;

# Added
_maybe_sign:
 | sign 
 ;
 
unsigned_numeric_literal:
 exact_numeric_literal | approximate_numeric_literal
 ;

# Modified
exact_numeric_literal:
# unsigned_integer [ period [ unsigned_integer ] ] | period unsigned_integer
 unsigned_integer _maybe_period_maybe_unsigned_integer | . unsigned_integer
 ;
 
# Added
_maybe_period_maybe_unsigned_integer:
 | . _maybe_unsigned_integer
 ;
 
# Added
_maybe_unsigned_integer:
 | unsigned_integer
 ;


sign:
 + | -
 ;

# Modified
approximate_numeric_literal:
# mantissa E exponent
 { $mant = int(rand(2147483648))-int(rand(4294967296)); $exp = int(rand(2147483648))-int(rand(4294967296)); $mant.'E'.$exp }
 ;

mantissa:
 exact_numeric_literal
 ;

exponent:
 signed_integer
 ;

# Modified
signed_integer:
# [ sign ] unsigned_integer
 _maybe_sign unsigned_integer
 ;

# Modified
# Heavily modified
unsigned_integer:
# digit...
 _int_unsigned
 ;

datetime_literal:
 date_literal | time_literal | timestamp_literal
 ;

date_literal:
 DATE date_string
 ;

time_literal:
 TIME time_string
 ;

timestamp_literal:
 TIMESTAMP timestamp_string
 ;

date_string:
 ' unquoted_date_string '
 ;

time_string:
 ' unquoted_time_string '
 ;

timestamp_string:
 ' unquoted_timestamp_string '
 ;

time_zone_interval:
 sign hours_value:minutes_value
 ;

date_value:
 years_value-months_value-days_value
 ;

time_value:
 hours_value:minutes_value:seconds_value
 ;

# Modified
interval_literal:
# interval [ sign ] interval_string interval_qualifier
 INTERVAL _maybe_sign interval_string interval_qualifier
 ;

interval_string:
 ' unquoted_interval_string '
 ;

unquoted_date_string:
 date_value
 ;

# Modified
unquoted_time_string:
# time_value [ time_zone_interval ]
 time_value _maybe_time_zone_interval
 ;
 
# Added
_maybe_time_zone_interval:
 |
# Not supported
# time_zone_interval
 ;

unquoted_timestamp_string:
 unquoted_date_string space unquoted_time_string
 ;

# Modified
unquoted_interval_string:
# [ sign ] { year_month_literal | day_time_literal }
 _maybe_sign _year_month_literal_or_day_time_literal
 ;

# Added
_year_month_literal_or_day_time_literal:
 year_month_literal | day_time_literal
 ;
 
# Modified
year_month_literal:
# years_value [ - months_value ] | months_value
 years_value _maybe_minus_sign_month_value | months_value
 ;
 
# Added
_maybe_minus_sign_month_value:
 | - months_value
 ;

day_time_literal:
 day_time_interval | time_interval
 ;

# Modified
day_time_interval:
# days_value [ space hours_value [ colon minutes_value [ colon seconds_value ] ] ]
 days_value _maybe_space_hours_value_maybe_colon_minutes_value_maybe_colon_seconds_value
 ;
 
# Added
_maybe_space_hours_value_maybe_colon_minutes_value_maybe_colon_seconds_value:
 | space hours_value _maybe_colon_minutes_value_maybe_colon_seconds_value
 ;
 
# Added
_maybe_colon_minutes_value_maybe_colon_seconds_value:
 | :minutes_value _maybe_colon_seconds_value
 ;
 
# Added
_maybe_colon_seconds_value:
 | :seconds_value
 ;

# Modified
time_interval:
# hours_value [ colon minutes_value [ colon seconds_value ] ] | minutes_value [ colon seconds_value ] | seconds_value
 hours_value _maybe_colon_minutes_value_maybe_colon_seconds_value | minutes_value _maybe_colon_seconds_value | seconds_value
 ;

years_value:
 datetime_value
 ;

months_value:
 datetime_value
 ;

days_value:
 datetime_value
 ;

hours_value:
 datetime_value
 ;

minutes_value:
 datetime_value
 ;

# Modified
seconds_value:
# <seconds integer value> [ <period> [ <seconds fraction> ] 
 seconds_integer_value _maybe_period_maybe_seconds_fraction
 ;
 
# Added
_maybe_period_maybe_seconds_fraction:
 | . _maybe_seconds_fraction
 ;
 
# Added
_maybe_seconds_fraction:
 | seconds_fraction
 ;

seconds_integer_value:
 unsigned_integer
 ;

seconds_fraction:
 unsigned_integer
 ;

datetime_value:
 unsigned_integer
 ;

boolean_literal:
 TRUE | FALSE | UNKNOWN
 ;

identifier:
 actual_identifier
 ;

# Modified probabilities
actual_identifier:
   regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
 | regular_identifier 
# Not supported (quotes)
# | delimited_identifier 
# Not supported
# | unicode_delimited_identifier
 ;

# Modified
sql_language_identifier:
# sql_language_identifier_start [ sql_language_identifier_part... ]
 sql_language_identifier_start _maybe_sql_language_identifier_parts
 ;
 
# Added
# Modified probabilities
_maybe_sql_language_identifier_parts:
 | | | | 
 sql_language_identifier_part _maybe_sql_language_identifier_parts
 ;

sql_language_identifier_start:
 simple_latin_letter
 ;

sql_language_identifier_part:
 simple_latin_letter | digit | _
 ;

authorization_identifier:
 role_name | user_identifier
 ;

table_name:
 local_or_schema_qualified_name
 ;

domain_name:
 schema_qualified_name
 ;

# Modified
schema_name:
# [ catalog_name period ] unqualified_schema_name
 _maybe_catalog_name_period unqualified_schema_name
 ;

# Added
_maybe_catalog_name_period:
 | 
# Not supported
# catalog_name .
 ;
 
unqualified_schema_name:
 identifier
 ;

catalog_name:
 identifier
 ;

# Modified
schema_qualified_name:
# [ schema_name period ] qualified_identifier
 _maybe_schema_name_period qualified_identifier
 ;
 
# Added
_maybe_schema_name_period:
 | schema_name .
 ;

# Modified
local_or_schema_qualified_name:
# [ local_or_schema_qualifier period ] qualified_identifier
 _maybe_local_or_schema_qualifier_period qualified_identifier
 ;

# Added
_maybe_local_or_schema_qualifier_period:
 | local_or_schema_qualifier .
 ;
 
local_or_schema_qualifier:
 schema_name
# Not supported
# | local_qualifier
 ;

qualified_identifier:
 identifier
 ;

column_name:
 identifier
 ;

correlation_name:
 identifier
 ;

query_name:
 identifier
 ;

sql_client_module_name:
 identifier
 ;

procedure_name:
 identifier
 ;

schema_qualified_routine_name:
 schema_qualified_name
 ;

method_name:
 identifier
 ;

specific_name:
 schema_qualified_name
 ;

cursor_name:
 local_qualified_name
 ;

# Modified
local_qualified_name:
# [ local_qualifier period ] qualified_identifier
 _maybe_local_qualifier_period qualified_identifier
 ;

# Added
_maybe_local_qualifier_period:
 |
# Not supported 
# local_qualifier .
 ;
 
# Not supported
local_qualifier:
 MODULE
 ;

host_parameter_name:
 :identifier
 ;

sql_parameter_name:
 identifier
 ;

constraint_name:
 schema_qualified_name
 ;

external_routine_name:
 identifier | character_string_literal
 ;

trigger_name:
 schema_qualified_name
 ;

# Heavily modified
# TODO
collation_name:
# schema_qualified_name
   latin1_bin
 | utf8_bin
 ;

character_set_name:
# [ <schema name> <period> ] <SQL language identifier>
 _maybe_schema_name_period sql_language_identifier
 ;

transliteration_name:
 schema_qualified_name
 ;

transcoding_name:
 schema_qualified_name
 ;

schema_resolved_user_defined_type_name:
 user_defined_type_name
 ;

# Modified
user_defined_type_name:
# [ schema_name period ] qualified_identifier
 _maybe_schema_name_period qualified_identifier
 ;

attribute_name:
 identifier
 ;

field_name:
 identifier
 ;

savepoint_name:
 identifier
 ;

sequence_generator_name:
 schema_qualified_name
 ;

role_name:
 identifier
 ;

user_identifier:
 identifier
 ;

connection_name:
 simple_value_specification
 ;

sql_server_name:
 simple_value_specification
 ;

connection_user_name:
 simple_value_specification
 ;

sql_statement_name:
 statement_name | extended_statement_name
 ;

statement_name:
 identifier
 ;

# Modified
extended_statement_name:
# [ scope_option ] simple_value_specification
 _maybe_scope_option simple_value_specification
 ;
 
# Added
_maybe_scope_option:
 | scope_option 
 ;

dynamic_cursor_name:
 cursor_name | extended_cursor_name
 ;

# Modified
extended_cursor_name:
# [ scope_option ] simple_value_specification
 _maybe_scope_option simple_value_specification
 ;

descriptor_name:
 non_extended_descriptor_name
 ;

non_extended_descriptor_name:
 identifier
 ;

# Modified
extended_descriptor_name:
# [ scope_option ] simple_value_specification
 _maybe_scope_option simple_value_specification
 ;

scope_option:
 GLOBAL | LOCAL
 ;

window_name:
 identifier
 ;

data_type:
   predefined_type
 | row_type
 | path_resolved_user_defined_type_name
# Not supported
# | reference_type
# Not supported
# | collection_type
 ;

# Modified
predefined_type:
# character_string_type [ character set character_set_specification ] [ collate_clause ] | national_character_string_type [ collate_clause ] | binary_string_type | numeric_type | boolean_type | datetime_type | interval_type
 character_string_type _maybe_character_set_character_set_specification _maybe_collate_clause | national_character_string_type _maybe_collate_clause | binary_string_type | numeric_type | boolean_type | datetime_type | interval_type
 ;
 
# Added
_maybe_character_set_character_set_specification:
 | CHARACTER SET character_set_specification
 ;
 
# Added
_maybe_collate_clause:
 | collate_clause
 ;

# Modified
character_string_type:
# character [ ( character_length ) ] | char [ ( character_length ) ] | character varying ( character_length ) | char varying ( character_length ) | varchar ( character_length ) | character_large_object_type
   CHARACTER _maybe_left_paren_character_length_right_paren 
 | CHAR _maybe_left_paren_character_length_right_paren 
 | CHARACTER VARYING ( character_length ) 
 | CHAR VARYING ( character_length ) 
 | VARCHAR ( character_length ) 
 | character_large_object_type
 ;
 
# Added
_maybe_left_paren_character_length_right_paren:
 | ( character_length ) ;

# Modified
character_large_object_type:
# character large object [ ( character_large_object_length ) ] | char large object [ ( character_large_object_length ) ] | clob [ ( character_large_object_length ) ]
 character large object _maybe_left_paren_character_large_object_length_right_paren | char large object _maybe_left_paren_character_large_object_length_right_paren | clob _maybe_left_paren_character_large_object_length_right_paren
 ;
 
# Added
_maybe_left_paren_character_large_object_length_right_paren:
 | ( character_large_object_length ) ;

# Modified
national_character_string_type:
 # NATIONAL CHARACTER [ <left paren> <character length> <right paren> ] | NATIONAL CHAR [ <left paren> <character length> <right paren> ] | NCHAR [ <left paren> <character length> <right paren> ] | NATIONAL CHARACTER VARYING <left paren> <character length> <right paren> | NATIONAL CHAR VARYING <left paren> <character length> <right paren> | NCHAR VARYING <left paren> <character length> <right paren> | <national character large object type>
   NATIONAL CHARACTER _maybe_left_paren_character_length_right_paren
 | NATIONAL CHAR _maybe_left_paren_character_length_right_paren
 | NCHAR _maybe_left_paren_character_length_right_paren
 | NATIONAL CHARACTER VARYING _maybe_left_paren_character_length_right_paren
 | NATIONAL CHAR VARYING _maybe_left_paren_character_length_right_paren
 | NCHAR VARYING _maybe_left_paren_character_length_right_paren
 | national_character_large_object_type
 ;


# Modified
national_character_large_object_type:
# national character large object [ ( character_large_object_length ) ] | nchar large object [ ( character_large_object_length ) ] | nclob [ ( character_large_object_length ) ]
 national character large object _maybe_left_paren_character_large_object_length_right_paren | nchar large object _maybe_left_paren_character_large_object_length_right_paren | nclob _maybe_left_paren_character_large_object_length_right_paren
 ;

# Modified
binary_string_type:
# binary [ ( length ) ] | binary varying ( length ) | varbinary ( length ) | binary_large_object_string_type
   BINARY _maybe_left_paren_length_right_paren 
 | BINARY VARYING( length ) 
 | VARBINARY( length ) 
 | binary_large_object_string_type
 ;
 
# Added
_maybe_left_paren_length_right_paren:
 | ( length ) ;

# Modified
binary_large_object_string_type:
# binary large object [ ( large_object_length ) ] | blob [ ( large_object_length ) ]
 binary large object _maybe_left_paren_large_object_length_right_paren | blob _maybe_left_paren_large_object_length_right_paren
 ;
 
# Added
_maybe_left_paren_large_object_length_right_paren:
 | ( large_object_length ) ;

numeric_type:
 exact_numeric_type | approximate_numeric_type
 ;

# Modified
exact_numeric_type:
# numeric [ ( precision [ , scale ] ) ] | decimal [ ( precision [ , scale ] ) ] | dec [ ( precision [ , scale ] ) ] | smallint | integer | int | bigint
   NUMERIC _maybe_left_paren_precision_maybe_comma_scale_right_paren 
 | DECIMAL _maybe_left_paren_precision_maybe_comma_scale_right_paren 
 | DEC _maybe_left_paren_precision_maybe_comma_scale_right_paren 
 | SMALLING 
 | INTEGER 
 | INT 
 | BIGINT
 ;
 
# Added
_maybe_left_paren_precision_maybe_comma_scale_right_paren:
 | ( precision _maybe_comma_scale ) ;
 
# Added
_maybe_comma_scale:
 | , scale
 ;

# Modified
approximate_numeric_type:
# float [ ( precision ) ] | real | double precision
   FLOAT _maybe_left_paren_precision_right_paren 
 | REAL 
 | DOUBLE PRECISION
 ;
 
# Added
_maybe_left_paren_precision_right_paren:
 | ( precision ) ;

length:
 unsigned_integer
 ;

# Modified
character_length:
# length [ char_length_units ]
 length _maybe_char_length_units
 ;
 
# Added
_maybe_char_length_units:
 | char_length_units
 ;

# Modified
large_object_length:
# length [ multiplier ] | large_object_length_token
 length _maybe_multiplier | large_object_length_token
 ;
 
# Added
_maybe_multiplier:
 | multiplier
 ;

# Modified
character_large_object_length:
# large_object_length [ char_length_units ]
 large_object_length _maybe_char_length_units
 ;

char_length_units:
 CHARACTERS | OCTETS
 ;

precision:
 unsigned_integer
 ;

scale:
 unsigned_integer
 ;

boolean_type:
 BOOLEAN
 ;

# Modified
datetime_type:
# date | time [ ( time_precision ) ] [ with_or_without_time_zone ] | timestamp [ ( timestamp_precision ) ] [ with_or_without_time_zone ]
   DATE 
 | TIME _maybe_left_paren_time_precision_right_paren _maybe_with_or_without_time_zone 
 | TIMESTAMP _maybe_left_paren_timestamp_precision_right_paren _maybe_with_or_without_time_zone
 ;
 
# Added
_maybe_left_paren_time_precision_right_paren:
 | ( time_precision ) ;
 
# Added
_maybe_with_or_without_time_zone:
 | with_or_without_time_zone
 ;
 
# Added
_maybe_left_paren_timestamp_precision_right_paren:
 | ( timestamp_precision ) ;

with_or_without_time_zone:
   WITH time zone 
 | WITHOUT time zone
 ;

time_precision:
 time_fractional_seconds_precision
 ;

timestamp_precision:
 time_fractional_seconds_precision
 ;

time_fractional_seconds_precision:
 unsigned_integer
 ;

interval_type:
 INTERVAL interval_qualifier
 ;

row_type:
 ROW row_type_body
 ;

# Modified
row_type_body:
# ( field_definition [ { , field_definition }... ] ) 
 ( field_definition _maybe_comma_field_definition_multi ) 
 ;

# Added
_maybe_comma_field_definition_multi:
 | | | | | |
 , field_definition _maybe_comma_field_definition_multi
 ;
 
# Modified
# Not supported
reference_type:
# ref ( referenced_type ) [ scope_clause ]
 REF( referenced_type ) _maybe_scope_clause
 ;
 
# Added
_maybe_scope_clause:
 | scope_clause
 ;

scope_clause:
 scope table_name
 ;

referenced_type:
 path_resolved_user_defined_type_name
 ;

path_resolved_user_defined_type_name:
 user_defined_type_name
 ;

# Not supported
collection_type:
 array_type | multiset_type
 ;

# Modified 
# Not supported
array_type:
# data_type array [ left_bracket_or_trigraph maximum_cardinality right_bracket_or_trigraph ]
 data_type ARRAY _maybe_left_bracket_or_trigraph_maximum_cardinality_right_bracket_or_trigraph
 ;
 
# Added
_maybe_left_bracket_or_trigraph_maximum_cardinality_right_bracket_or_trigraph:
 | left_bracket_or_trigraph maximum_cardinality right_bracket_or_trigraph
 ;

maximum_cardinality:
 unsigned_integer
 ;

multiset_type:
 data_type MULTISET
 ;

field_definition:
 field_name data_type
 ;

# Modified probabilities
value_expression_primary:
   parenthesized_value_expression 
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 ;

parenthesized_value_expression:
 ( value_expression ) 
 ;

# Modified probabilities
nonparenthesized_value_expression_primary:
   unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | unsigned_value_specification 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | column_reference 
 | set_function_specification 
 | set_function_specification 
 | set_function_specification 
 | window_function 
 | window_function 
 | window_function 
# Not supported
# | nested_window_function 
 | scalar_subquery 
 | case_expression 
 | case_expression 
 | cast_specification 
 | cast_specification 
 | field_reference 
 | field_reference 
 | field_reference 
# Not supported
# | subtype_treatment 
 | method_invocation 
 | static_method_invocation 
# Not supported
# | new_specification 
# Not supported
# | attribute_or_method_reference 
 | reference_resolution 
 | collection_value_constructor 
 | array_element_reference 
# Not supported
# | multiset_element_reference 
# Not supported
# | next_value_expression 
 | routine_invocation
 ;

collection_value_constructor:
 array_value_constructor | multiset_value_constructor
 ;

value_specification:
 literal | general_value_specification
 ;

unsigned_value_specification:
   unsigned_literal 
 | general_value_specification
 ;

general_value_specification:
   host_parameter_specification
 | sql_parameter_reference
 | dynamic_parameter_specification
 | embedded_variable_specification
 | current_collation_specification
# Not supported
# | CURRENT_CATALOG
# Not supported
# | CURRENT_DEFAULT_TRANSFORM_GROUP
# Not supported
# | CURRENT_PATH
 | CURRENT_ROLE
# Not supported
# | CURRENT_SCHEMA
# Not supported
# | CURRENT_TRANSFORM_GROUP_FOR_TYPE path_resolved_user_defined_type_name
 | CURRENT_USER
# Not supported
# | SESSION_USER
# Not supported
# | SYSTEM_USER
 | USER
 | VALUE
 ;

simple_value_specification:
   literal
# Not supported
# | host_parameter_name
 | sql_parameter_reference
# Not supported
# | embedded_variable_name
 ;

target_specification:
 host_parameter_specification | sql_parameter_reference | column_reference | target_array_element_specification | dynamic_parameter_specification | embedded_variable_specification
 ;

# TODO
simple_target_specification:
 host_parameter_name | sql_parameter_reference | column_reference | embedded_variable_name
 ;

# Modified
host_parameter_specification:
# host_parameter_name [ indicator_parameter ]
 host_parameter_name _maybe_indicator_parameter
 ;
 
# Added
_maybe_indicator_parameter:
 | indicator_parameter
 ;

dynamic_parameter_specification:
 question_mark
 ;

# Modified
embedded_variable_specification:
# embedded_variable_name [ indicator_variable ]
 embedded_variable_name _maybe_indicator_variable
 ;
 
# Added
_maybe_indicator_variable:
 | indicator_variable
 ;

# Modified
indicator_variable:
# [ indicator ] embedded_variable_name
 _maybe_indicator embedded_variable_name
 ;

# Added
_maybe_indicator:
 | indicator
 ;
 
# Modified
indicator_parameter:
# [ indicator ] host_parameter_name
 _maybe_indicator host_parameter_name
 ;

target_array_element_specification:
 target_array_reference left_bracket_or_trigraph simple_value_specification right_bracket_or_trigraph
 ;

target_array_reference:
 sql_parameter_reference | column_reference
 ;

current_collation_specification:
 COLLATION FOR ( string_value_expression ) ;

contextually_typed_value_specification:
 implicitly_typed_value_specification | default_specification
 ;

implicitly_typed_value_specification:
 null_specification | empty_specification
 ;

null_specification:
 NULL
 ;

empty_specification:
 ARRAY left_bracket_or_trigraph right_bracket_or_trigraph | MULTISET left_bracket_or_trigraph right_bracket_or_trigraph
 ;

default_specification:
 DEFAULT
 ;

# Modified
identifier_chain:
# identifier [ { period identifier }... ]
 identifier _maybe_period_identifier_multi
 ;
 
# Added
_maybe_period_identifier_multi:
 | | | | | |
 . identifier _maybe_period_identifier_multi
 ;

basic_identifier_chain:
 identifier_chain
 ;

column_reference:
 basic_identifier_chain
# Not supported
# | MODULE . qualified_identifier . column_name
 ;

sql_parameter_reference:
 basic_identifier_chain
 ;

set_function_specification:
   aggregate_function 
 | grouping_operation
 ;

# Modified
grouping_operation:
# grouping ( column_reference [ { , column_reference }... ] ) 
 GROUPING( column_reference _maybe_comma_column_reference_multi ) ;
 
# Added
_maybe_comma_column_reference_multi:
 | | | | | |
 , column_reference _maybe_comma_column_reference_multi
 ;

window_function:
 window_function_type OVER window_name_or_specification
 ;

window_function_type:
 rank_function_type() | ROW_NUMBER() | aggregate_function | ntile_function | lead_or_lag_function | first_or_last_value_function | nth_value_function
 ;

rank_function_type:
 RANK | DENSE_RANK | PERCENT_RANK | CUME_DIST
 ;

ntile_function:
 NTILE( number_of_tiles ) ;

number_of_tiles:
 simple_value_specification | dynamic_parameter_specification
 ;

# Modified
lead_or_lag_function:
# lead_or_lag ( lead_or_lag_extent [ , offset [ , default_expression ] ] ) [ null_treatment ]
 lead_or_lag ( lead_or_lag_extent _maybe_comma_offset_maybe_comma_default_expression ) _maybe_null_treatment
 ;

# Added
_maybe_comma_offset_maybe_comma_default_expression:
 | , offset _maybe_comma_default_expression
 ;
 
# Added
_maybe_comma_default_expression:
 | , default_expression
 ;
 
# Added
_maybe_null_treatment:
 |
# Not supported
# null_treatment
 ;
 
lead_or_lag:
 LEAD | LAG
 ;

lead_or_lag_extent:
 value_expression
 ;

offset:
 exact_numeric_literal
 ;

default_expression:
 value_expression
 ;

# Not supported
null_treatment:
 RESPECT NULLS | IGNORE NULLS
 ;

# Modified
first_or_last_value_function:
# first_or_last_value ( value_expression ) [ null_treatment ]
 first_or_last_value ( value_expression ) _maybe_null_treatment
 ;

first_or_last_value:
 FIRST_VALUE | LAST_VALUE
 ;

# Modified
nth_value_function:
# nth_value ( value_expression , nth_row ) [ from_first_or_last ] [ null_treatment ]
 NTH_VALUE( value_expression , nth_row ) _maybe_from_first_or_last _maybe_null_treatment
 ;
 
# Added
_maybe_from_first_or_last:
 | from_first_or_last
 ;

nth_row:
 simple_value_specification | dynamic_parameter_specification
 ;

from_first_or_last:
 FROM FIRST | FROM LAST
 ;

window_name_or_specification:
 window_name | in_line_window_specification
 ;

in_line_window_specification:
 window_specification
 ;

# Not supported
nested_window_function:
   nested_row_number_function
 | value_of_expression_at_row
 ;

# Not supported
nested_row_number_function:
 ROW_NUMBER( row_marker ) ;

# Modified
# Not supported
value_of_expression_at_row:
# value_of ( value_expression at row_marker_expression [ , value_of_default_value ] ) 
 VALUE_OF ( value_expression at row_marker_expression _maybe_comma_value_of_default_value ) 
 ;
 
# Added
_maybe_comma_value_of_default_value:
 | , value_of_default_value
 ;

# Not supported
row_marker:
   BEGIN_PARTITION 
 | BEGIN_FRAME
 | CURRENT_ROW
 | FRAME_ROW
 | END_FRAME
 | END_PARTITION
 ;

# Modified
row_marker_expression:
# row_marker [ row_marker_delta ]
 row_marker _maybe_row_marker_delta
 ;
 
# Added
_maybe_row_marker_delta:
 | row_marker_delta
 ;

row_marker_delta:
 + row_marker_offset | - row_marker_offset
 ;

row_marker_offset:
 simple_value_specification | dynamic_parameter_specification
 ;

value_of_default_value:
 value_expression
 ;

case_expression:
   case_abbreviation 
 | case_specification
 ;

# Modified
case_abbreviation:
# nullif ( value_expression , value_expression ) | coalesce ( value_expression { , value_expression }... ) 
  NULLIF ( value_expression , value_expression ) | COALESCE ( value_expression _comma_value_expression_multi ) ;
 
# Added
_comma_value_expression_multi:
   , value_expression 
 | , value_expression
 | , value_expression
 | , value_expression
 | , value_expression
 | , value_expression _comma_value_expression_multi
 ;

case_specification:
 simple_case | searched_case
 ;

# Modified
simple_case:
# case case_operand simple_when_clause... [ else_clause ] end
 CASE case_operand _simple_when_clause_multi _maybe_else_clause end
 ;
 
# Added
_simple_when_clause_multi:
   simple_when_clause
 | simple_when_clause
 | simple_when_clause
 | simple_when_clause
 | simple_when_clause
 | simple_when_clause _simple_when_clause_multi
 ;

# Added
_maybe_else_clause:
 | else_clause
 ;

# Modified
searched_case:
# case searched_when_clause... [ else_clause ] end
 CASE _searched_when_clause_multi _maybe_else_clause end
 ;
 
# Added
_searched_when_clause_multi:
   searched_when_clause 
 | searched_when_clause
 | searched_when_clause
 | searched_when_clause
 | searched_when_clause
 | searched_when_clause _searched_when_clause_multi
 ;

simple_when_clause:
 WHEN when_operand_list THEN result
 ;

searched_when_clause:
 WHEN search_condition THEN result
 ;

else_clause:
 ELSE result
 ;

case_operand:
 row_value_predicand | overlaps_predicate_part_1
 ;

# Modified
when_operand_list:
# when_operand [ { , when_operand }... ]
 when_operand _maybe_comma_when_operand_multi
 ;
 
# Added
_maybe_comma_when_operand_multi:
 | | | | |
 , when_operand _maybe_comma_when_operand_multi
 ;

when_operand:
 row_value_predicand | comparison_predicate_part_2 | between_predicate_part_2 | in_predicate_part_2 | character_like_predicate_part_2 | octet_like_predicate_part_2 | similar_predicate_part_2 | regex_like_predicate_part_2 | null_predicate_part_2 | quantified_comparison_predicate_part_2
 ;

result:
 result_expression | NULL
 ;

result_expression:
 value_expression
 ;

cast_specification:
 CAST( cast_operand AS cast_target ) ;

cast_operand:
 value_expression | implicitly_typed_value_specification
 ;

cast_target:
# Not supported
# domain_name | 
 data_type
 ;

# Not supported
next_value_expression:
 NEXT VALUE FOR sequence_generator_name
 ;

field_reference:
 value_expression_primary . field_name
 ;

# Not supported
subtype_treatment:
 TREAT ( subtype_operand AS target_subtype ) ;

subtype_operand:
 value_expression
 ;

target_subtype:
 path_resolved_user_defined_type_name
# Not supported
# | reference_type
 ;

method_invocation:
 direct_invocation | generalized_invocation
 ;

# Modified
direct_invocation:
# value_expression_primary period method_name [ sql_argument_list ]
 value_expression_primary . method_name _maybe_sql_argument_list
 ;
 
# Added
_maybe_sql_argument_list:
 | sql_argument_list
 ;

# Modified
generalized_invocation:
# ( value_expression_primary AS data_type ) period method_name [ sql_argument_list ]
 ( value_expression_primary AS data_type ) . method_name _maybe_sql_argument_list
 ;

method_selection:
 routine_invocation
 ;

constructor_method_selection:
 routine_invocation
 ;

# Modified
static_method_invocation:
# path_resolved_user_defined_type_name double_colon method_name [ sql_argument_list ]
 path_resolved_user_defined_type_name :: method_name _maybe_sql_argument_list
 ;

static_method_selection:
 routine_invocation
 ;

new_specification:
 NEW path_resolved_user_defined_type_name sql_argument_list
 ;

new_invocation:
 method_invocation | routine_invocation
 ;

# Modified
# Not supported
attribute_or_method_reference:
# value_expression_primary dereference_operator qualified_identifier [ sql_argument_list ]
 value_expression_primary dereference_operator qualified_identifier _maybe_sql_argument_list
 ;

dereference_operator:
 right_arrow
 ;

dereference_operation:
 reference_value_expression dereference_operator attribute_name
 ;

method_reference:
 value_expression_primary dereference_operator method_name sql_argument_list
 ;

# Not supported
reference_resolution:
 DEREF( reference_value_expression ) ;

array_element_reference:
 array_value_expression left_bracket_or_trigraph numeric_value_expression right_bracket_or_trigraph
 ;

# Not supported
multiset_element_reference:
 ELEMENT( multiset_value_expression ) ;

# Modified probabilities
value_expression:
   common_value_expression 
 | common_value_expression 
 | common_value_expression 
 | common_value_expression 
 | common_value_expression 
 | boolean_value_expression 
 | boolean_value_expression 
 | boolean_value_expression 
 | row_value_expression
 ;

common_value_expression:
   numeric_value_expression 
 | string_value_expression 
 | datetime_value_expression 
 | interval_value_expression 
 | user_defined_type_value_expression 
 | reference_value_expression 
 | collection_value_expression
 ;

user_defined_type_value_expression:
 value_expression_primary
 ;

reference_value_expression:
 value_expression_primary
 ;

collection_value_expression:
 array_value_expression | multiset_value_expression
 ;

# Modified probabilities
numeric_value_expression:
   term 
 | term 
 | term 
 | term 
 | term 
 | term 
 | term 
 | term 
 | term 
 | term 
 | numeric_value_expression + term 
 | numeric_value_expression - term
 ;

# Modified probabilities
term:
   factor 
 | factor 
 | factor 
 | factor 
 | factor 
 | factor 
 | factor 
 | factor 
 | term * factor 
 | term solidus factor
 ;

# Modified
factor:
# [ sign ] numeric_primary
 _maybe_sign numeric_primary
 ;

# Modified probabilities
numeric_primary:
   value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | value_expression_primary 
 | numeric_value_function
 ;

numeric_value_function:
   position_expression 
 | regex_occurrences_function 
 | regex_position_expression 
 | extract_expression 
 | length_expression 
 | cardinality_expression 
 | max_cardinality_expression 
 | absolute_value_expression 
 | modulus_expression 
 | natural_logarithm 
 | exponential_function 
 | power_function 
 | square_root 
 | floor_function 
 | ceiling_function 
 | width_bucket_function
 ;

position_expression:
 character_position_expression | binary_position_expression
 ;

# Modified
regex_occurrences_function:
# occurrences_regex ( xquery_pattern [ flag xquery_option_flag ] in regex_subject_string [ from start_position ] [ using char_length_units ] )
 OCCURRENCES_REGEX ( xquery_pattern _maybe_flag_xquery_option_flag IN regex_subject_string _maybe_from_start_position _maybe_using_char_length_units ) 
 ;
 
# Added
_maybe_flag_xquery_option_flag:
 | FLAG xquery_option_flag
 ;
 
# Added
_maybe_from_start_position:
 | FROM start_position
 ;
 
# Added
_maybe_using_char_length_units:
 | USING char_length_units
 ;
 
xquery_pattern:
 character_value_expression
 ;

xquery_option_flag:
 character_value_expression
 ;

regex_subject_string:
 character_value_expression
 ;

# Modified
regex_position_expression:
# position_regex ( [ regex_position_start_or_after ] xquery_pattern [ flag xquery_option_flag ] in regex_subject_string [ from start_position ] [ using char_length_units ] [ occurrence regex_occurrence ]
 POSITION_REGEX ( _maybe_regex_position_start_or_after xquery_pattern _maybe_flag_xquery_option_flag IN regex_subject_string _maybe_from_start_position _maybe_using_char_length_units _maybe_occurrence_regex_occurrence
 ;
 
# Added
_maybe_regex_position_start_or_after:
 | regex_position_start_or_after
 ;
 
# Added
_maybe_occurrence_regex_occurrence:
 | OCCURRENCE regex_occurrence
 ;

regex_position_start_or_after:
 START | AFTER
 ;

regex_occurrence:
 numeric_value_expression
 ;

regex_capture_group:
 numeric_value_expression
 ;

# Modified
character_position_expression:
# position ( character_value_expression_1 in character_value_expression_2 [ using char_length_units ] ) 
 POSITION( character_value_expression_1 IN character_value_expression_2 _maybe_using_char_length_units ) ;

character_value_expression_1:
 character_value_expression
 ;

character_value_expression_2:
 character_value_expression
 ;

binary_position_expression:
 POSITION( binary_value_expression in binary_value_expression ) ;

length_expression:
 char_length_expression | octet_length_expression
 ;

# Modified
char_length_expression:
# { char_length | character_length } ( character_value_expression [ USING char_length_units ] ) _char_length_or_character_length ( character_value_expression _maybe_using_char_length_units ) ;
 
# Added
_char_length_or_character_length:
 char_length | character_length
 ;

octet_length_expression:
 octet_length ( string_value_expression ) ;

extract_expression:
 EXTRACT( extract_field FROM extract_source ) ;

extract_field:
 primary_datetime_field | time_zone_field
 ;

time_zone_field:
 timezone_hour | timezone_minute
 ;

extract_source:
 datetime_value_expression | interval_value_expression
 ;

cardinality_expression:
 cardinality ( collection_value_expression ) ;

max_cardinality_expression:
 array_max_cardinality ( array_value_expression ) ;

absolute_value_expression:
 ABS( numeric_value_expression ) ;

modulus_expression:
 MOD( numeric_value_expression_dividend , numeric_value_expression_divisor ) ;

numeric_value_expression_dividend:
 numeric_value_expression
 ;

numeric_value_expression_divisor:
 numeric_value_expression
 ;

natural_logarithm:
 LN( numeric_value_expression ) ;

exponential_function:
 EXP( numeric_value_expression ) ;

power_function:
 POWER( numeric_value_expression_base , numeric_value_expression_exponent ) ;

numeric_value_expression_base:
 numeric_value_expression
 ;

numeric_value_expression_exponent:
 numeric_value_expression
 ;

square_root:
 SQRT( numeric_value_expression ) ;

floor_function:
 FLOOR( numeric_value_expression ) ;

# Modified
ceiling_function:
# { ceil | ceiling } ( numeric_value_expression ) 
 _ceil_or_ceiling ( numeric_value_expression ) ;

# Added
_ceil_or_ceiling:
 CEIL | CEILING
 ;
 
 
width_bucket_function:
 width_bucket ( width_bucket_operand , width_bucket_bound_1 , width_bucket_bound_2 , width_bucket_count ) ;

width_bucket_operand:
 numeric_value_expression
 ;

width_bucket_bound_1:
 numeric_value_expression
 ;

width_bucket_bound_2:
 numeric_value_expression
 ;

width_bucket_count:
 numeric_value_expression
 ;

string_value_expression:
   character_value_expression 
 | binary_value_expression
 ;

# Modified probabilities
character_value_expression:
   concatenation 
 | character_factor
 | character_factor
 | character_factor
 | character_factor
 | character_factor
 | character_factor
 ;

concatenation:
 character_value_expression concatenation_operator character_factor
 ;

# Modified
character_factor:
# character_primary [ collate_clause ]
 character_primary _maybe_collate_clause
 ;

character_primary:
   value_expression_primary 
 | string_value_function
 ;

# Modified probabilities
binary_value_expression:
   binary_concatenation 
 | binary_factor
 | binary_factor
 | binary_factor
 | binary_factor
 | binary_factor
 | binary_factor
 | binary_factor
 ;

binary_factor:
 binary_primary
 ;

binary_primary:
   value_expression_primary 
 | string_value_function
 ;

binary_concatenation:
 binary_value_expression concatenation_operator binary_factor
 ;

string_value_function:
   character_value_function 
 | binary_value_function
 ;

character_value_function:
   character_substring_function 
 | regular_expression_substring_function 
 | regex_substring_function 
 | fold 
 | transcoding 
 | character_transliteration 
 | regex_transliteration 
 | trim_function 
 | character_overlay_function 
 | normalize_function 
 | specific_type_method
 ;

# Modified
character_substring_function:
# substring ( character_value_expression from start_position [ FOR string_length ] [ using char_length_units ] ) 
 SUBSTRING( character_value_expression FROM start_position _maybe_for_string_length _maybe_using_char_length_units ) ;
 
# Added
_maybe_for_string_length:
 | FOR string_length
 ;
 
regular_expression_substring_function:
 SUBSTRING( character_value_expression similar character_value_expression escape escape_character ) ;

# Modified
regex_substring_function:
# substring_regex ( xquery_pattern [ flag xquery_option_flag ] in regex_subject_string [ from start_position ] [ using char_length_units ] [ occurrence regex_occurrence ] [ group regex_capture_group ] ) 
 substring_regex ( xquery_pattern _maybe_flag_xquery_option_flag IN regex_subject_string _maybe_from_start_position _maybe_using_char_length_units _maybe_occurrence_regex_occurrence _maybe_group_regex_capture_group ) ;

# Added
_maybe_group_regex_capture_group:
 | group regex_capture_group
 ;
 
# Modified
fold:
# { upper | lower } ( character_value_expression ) 
 _upper_or_lower ( character_value_expression ) ;

# Added
_upper_or_lower:
 UPPER | LOWER
 ;
 
transcoding:
 CONVERT( character_value_expression using transcoding_name ) ;

character_transliteration:
 TRANSLATE( character_value_expression )
 ;

# Modified
regex_transliteration:
# translate_regex ( xquery_pattern [ flag xquery_option_flag ] in regex_subject_string [ with xquery_replacement_string ] [ from start_position ] [ using char_length_units ] [ occurrence regex_transliteration_occurrence ] ) 
 TRANSLATE_REGEX ( xquery_pattern _maybe_flag_xquery_option_flag IN regex_subject_string _maybe_with_xquery_replacement_string _maybe_from_start_position _maybe_using_char_length_units _maybe_occurrence_regex_transliteration_occurrence ) ;
 
# Added
_maybe_with_xquery_replacement_string:
 | WITH xquery_replacement_string
 ;
 
# Added
_maybe_occurrence_regex_transliteration_occurrence:
 | OCCURRENCE regex_transliteration_occurrence
 ;

xquery_replacement_string:
 character_value_expression
 ;

regex_transliteration_occurrence:
 regex_occurrence | ALL
 ;

trim_function:
 TRIM( trim_operands ) ;

# Modified
trim_operands:
# [ [ trim_specification ] [ trim_character ] from ] trim_source
 _maybe_maybe_trim_specification_maybe_trim_character_from trim_source
 ;

# Added
_maybe_maybe_trim_specification_maybe_trim_character_from:
 | _maybe_trim_specification _maybe_trim_character FROM
 ;
 
# Added
_maybe_trim_specification:
 | trim_specification
 ;
 
# Added
_maybe_trim_character:
 | trim_character
 ;
 
trim_source:
 character_value_expression
 ;

trim_specification:
 LEADING | TRAILING | BOTH
 ;

trim_character:
 character_value_expression
 ;

# Modified
character_overlay_function:
# overlay ( character_value_expression placing character_value_expression from start_position [ FOR string_length ] [ using char_length_units ] )
 overlay ( character_value_expression placing character_value_expression FROM start_position _maybe_for_string_length _maybe_using_char_length_units ) ;

# Modified
normalize_function:
# normalize ( character_value_expression [ , normal_form [ , normalize_function_result_length ] ] ) normalize ( character_value_expression _maybe_comma_normal_form_maybe_comma_normalize_function_result_length ) ;

# Added
_maybe_comma_normal_form_maybe_comma_normalize_function_result_length:
 | , normal_form _maybe_comma_normalize_function_result_length
 ;
 
# Added
_maybe_comma_normalize_function_result_length:
 | , normalize_function_result_length
 ;
 
normal_form:
 nfc | nfd | nfkc | nfkd
 ;

normalize_function_result_length:
 character_length | character_large_object_length
 ;

# Modified
specific_type_method:
# user_defined_type_value_expression period specifictype [ ( ) ]
 user_defined_type_value_expression . SPECIFICTYPE _maybe_left_paren_right_paren
 ;
 
# Added
_maybe_left_paren_right_paren:
 | ( ) ;

# TODO
binary_value_function:
 
 ;

# Modified
binary_substring_function:
# substring ( binary_value_expression from start_position [ FOR string_length ] ) 
 SUBSTRING( binary_value_expression FROM start_position _maybe_for_string_length ) ;

binary_trim_function:
 TRIM( binary_trim_operands ) ;

# Modified
binary_trim_operands:
# [ [ trim_specification ] [ trim_octet ] from ] binary_trim_source
 _maybe_maybe_trim_specification_maybe_trim_octet_from binary_trim_source
 ;
 
# Added
_maybe_maybe_trim_specification_maybe_trim_octet_from:
 | _maybe_trim_specification _maybe_trim_octet FROM
 ;
 
# Added
_maybe_trim_octet:
 | trim_octet
 ;

binary_trim_source:
 binary_value_expression
 ;

trim_octet:
 binary_value_expression
 ;

# Modified
binary_overlay_function:
# overlay ( binary_value_expression placing binary_value_expression from start_position [ FOR string_length ] ) 
 overlay ( binary_value_expression placing binary_value_expression FROM start_position _maybe_for_string_length ) ;

start_position:
 numeric_value_expression
 ;

string_length:
 numeric_value_expression
 ;

# Modified probabilities
datetime_value_expression:
   datetime_term 
 | datetime_term 
 | datetime_term 
 | datetime_term 
 | datetime_term 
 | datetime_term 
 | interval_value_expression + datetime_term 
 | datetime_value_expression + interval_term 
 | datetime_value_expression - interval_term
 ;

datetime_term:
 datetime_factor
 ;

# Modified
datetime_factor:
# datetime_primary [ time_zone ]
 datetime_primary _maybe_time_zone
 ;
 
# Added
_maybe_time_zone:
 | time_zone
 ;

datetime_primary:
 value_expression_primary | datetime_value_function
 ;

time_zone:
 at time_zone_specifier
 ;

time_zone_specifier:
 local | time zone interval_primary
 ;

datetime_value_function:
 current_date_value_function | current_time_value_function | current_timestamp_value_function | current_local_time_value_function | current_local_timestamp_value_function
 ;

current_date_value_function:
 CURRENT_DATE
 ;

# Modified
current_time_value_function:
# current_time [ ( time_precision ) ]
 CURRENT_TIME _maybe_left_paren_time_precision_right_paren
 ;

# Modified
current_local_time_value_function:
# localtime [ ( time_precision ) ]
 localtime _maybe_left_paren_time_precision_right_paren
 ;

# Modified
current_timestamp_value_function:
# current_timestamp [ ( timestamp_precision ) ]
 CURRENT_TIMESTAMP _maybe_left_paren_timestamp_precision_right_paren
 ;

# Modified
current_local_timestamp_value_function:
# localtimestamp [ ( timestamp_precision ) ]
 LOCALTIMESTAMP _maybe_left_paren_timestamp_precision_right_paren
 ;

# Modified probabilities
interval_value_expression:
   interval_term 
 | interval_term 
 | interval_term 
 | interval_term 
 | interval_term 
 | interval_term 
 | interval_term 
 | interval_value_expression_1 + interval_term_1 
 | interval_value_expression_1 - interval_term_1 
 | ( datetime_value_expression - datetime_term ) interval_qualifier
 ;

# Modified probabilities
interval_term:
   interval_factor 
 | interval_factor 
 | interval_factor 
 | interval_factor 
 | interval_factor 
 | interval_factor 
 | interval_factor 
 | interval_term_2 * factor 
 | interval_term_2 solidus factor 
 | term * interval_factor
 ;

# Modified
interval_factor:
# [ sign ] interval_primary
 _maybe_sign interval_primary
 ;

# Modified
# Modified probabilities
interval_primary:
# value_expression_primary [ interval_qualifier ] | interval_value_function
   value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | value_expression_primary _maybe_interval_qualifier 
 | interval_value_function
 ;
 
# Added
_maybe_interval_qualifier:
 | interval_qualifier
 ;

interval_value_expression_1:
 interval_value_expression
 ;

interval_term_1:
 interval_term
 ;

interval_term_2:
 interval_term
 ;

interval_value_function:
 interval_absolute_value_function
 ;

interval_absolute_value_function:
 ABS( interval_value_expression ) ;

# Modified probabilities
boolean_value_expression:
   boolean_term 
 | boolean_term
 | boolean_term
 | boolean_term
 | boolean_term
 | boolean_value_expression OR boolean_term
 ;

# Modified probabilities
boolean_term:
   boolean_factor 
 | boolean_factor
 | boolean_factor
 | boolean_factor
 | boolean_factor
 | boolean_factor
 | boolean_factor
 | boolean_term and boolean_factor
 ;

# Modified
boolean_factor:
# [ not ] boolean_test
 _maybe_not boolean_test
 ;

# Added
_maybe_not:
 | NOT
 ;
 
# Modified
boolean_test:
# boolean_primary [ is [ not ] truth_value ]
 boolean_primary _maybe_is_maybe_not_truth_value
 ;
 
# Added
_maybe_is_maybe_not_truth_value:
 | IS _maybe_not truth_value
 ;

truth_value:
 TRUE | FALSE | UNKNOWN
 ;

# Modified probabilities
boolean_primary:
 predicate 
 | boolean_predicand
 | boolean_predicand
 | boolean_predicand
 | boolean_predicand
 | boolean_predicand
 | boolean_predicand
 | boolean_predicand
 ;

# Modified probabilities
boolean_predicand:
   parenthesized_boolean_value_expression 
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 | nonparenthesized_value_expression_primary
 ;

parenthesized_boolean_value_expression:
 ( boolean_value_expression ) ;

# Modified probabilities
array_value_expression:
   array_concatenation 
 | array_primary
 | array_primary
 | array_primary
 | array_primary
 | array_primary
 | array_primary
 | array_primary
 ;

array_concatenation:
 array_value_expression_1 concatenation_operator array_primary
 ;

array_value_expression_1:
 array_value_expression
 ;

# Modified probabilities
array_primary:
   array_value_function 
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 | value_expression_primary
 ;

array_value_function:
 trim_array_function
 ;

trim_array_function:
 trim_array ( array_value_expression , numeric_value_expression ) ;

array_value_constructor:
 array_value_constructor_by_enumeration | array_value_constructor_by_query
 ;

array_value_constructor_by_enumeration:
 ARRAY left_bracket_or_trigraph array_element_list right_bracket_or_trigraph
 ;

# Modified
array_element_list:
# array_element [ { , array_element }... ]
 array_element _maybe_comma_array_element_multi
 ;
 
# Added
_maybe_comma_array_element_multi:
 | | | | | |
 , array_element _maybe_comma_array_element_multi
 ;

array_element:
 value_expression
 ;

array_value_constructor_by_query:
 ARRAY table_subquery
 ;

# Modified
# Modified probabilities
multiset_value_expression:
# multiset_term | multiset_value_expression MULTISET union [ all | distinct ] multiset_term | multiset_value_expression MULTISET except [ all | distinct ] multiset_term
   multiset_term 
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_term
 | multiset_value_expression MULTISET UNION _maybe_all_or_distinct multiset_term 
 | multiset_value_expression MULTISET except _maybe_all_or_distinct multiset_term
 ;
 
# Added
_maybe_all_or_distinct:
 | ALL | DISTINCT
 ;

# Modified
# Modified probabilities
multiset_term:
# multiset_primary | multiset_term MULTISET intersect [ all | distinct ] multiset_primary
   multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_primary 
 | multiset_term MULTISET INTERSECT _maybe_all_or_distinct multiset_primary
 ;

multiset_primary:
 multiset_value_function | value_expression_primary
 ;

multiset_value_function:
 multiset_set_function
 ;

multiset_set_function:
 SET( multiset_value_expression ) ;

multiset_value_constructor:
 multiset_value_constructor_by_enumeration | multiset_value_constructor_by_query | table_value_constructor_by_query
 ;

multiset_value_constructor_by_enumeration:
 MULTISET left_bracket_or_trigraph multiset_element_list right_bracket_or_trigraph
 ;

# Modified
multiset_element_list:
# multiset_element [ { , multiset_element }... ]
 multiset_element _maybe_comma_multiset_element_multi
 ;
 
# Added
_maybe_comma_multiset_element_multi:
 | | | | | |
 , multiset_element _maybe_comma_multiset_element_multi
 ;

multiset_element:
 value_expression
 ;

multiset_value_constructor_by_query:
 MULTISET table_subquery
 ;

table_value_constructor_by_query:
 TABLE table_subquery
 ;

row_value_constructor:
 common_value_expression | boolean_value_expression | explicit_row_value_constructor
 ;

# Modified probablities
explicit_row_value_constructor:
   ( row_value_constructor_element , row_value_constructor_element_list ) 
 | ( row_value_constructor_element , row_value_constructor_element_list ) 
 | ( row_value_constructor_element , row_value_constructor_element_list ) 
 | ROW ( row_value_constructor_element_list ) 
 | ROW ( row_value_constructor_element_list ) 
 | ROW ( row_value_constructor_element_list ) 
 | ROW ( row_value_constructor_element_list ) 
 | ROW ( row_value_constructor_element_list ) 
 | row_subquery
 ;

# Modified
row_value_constructor_element_list:
# row_value_constructor_element [ { , row_value_constructor_element }... ]
 row_value_constructor_element _maybe_comma_row_value_constructor_element_multi
 ;
 
# Added
_maybe_comma_row_value_constructor_element_multi:
 | | | | | |
 , row_value_constructor_element
 ;

row_value_constructor_element:
 value_expression
 ;

contextually_typed_row_value_constructor:
 common_value_expression | boolean_value_expression | contextually_typed_value_specification | ( contextually_typed_value_specification ) | ( contextually_typed_row_value_constructor_element , contextually_typed_row_value_constructor_element_list ) | ROW ( contextually_typed_row_value_constructor_element_list ) ;

# Modified 
contextually_typed_row_value_constructor_element_list:
# contextually_typed_row_value_constructor_element [ { , contextually_typed_row_value_constructor_element }... ]
 contextually_typed_row_value_constructor_element _maybe_comma_contextually_typed_row_value_constructor_element_multi
 ;
 
# Added
_maybe_comma_contextually_typed_row_value_constructor_element_multi:
 | | | | | |
 , contextually_typed_row_value_constructor_element _maybe_comma_contextually_typed_row_value_constructor_element_multi
 ;

contextually_typed_row_value_constructor_element:
 value_expression | contextually_typed_value_specification
 ;

row_value_constructor_predicand:
 common_value_expression | boolean_predicand | explicit_row_value_constructor
 ;

row_value_expression:
 row_value_special_case | explicit_row_value_constructor
 ;

table_row_value_expression:
 row_value_special_case | row_value_constructor
 ;

contextually_typed_row_value_expression:
 row_value_special_case | contextually_typed_row_value_constructor
 ;

row_value_predicand:
 row_value_special_case | row_value_constructor_predicand
 ;

row_value_special_case:
 nonparenthesized_value_expression_primary
 ;

table_value_constructor:
 VALUES row_value_expression_list
 ;

# Modified
row_value_expression_list:
# table_row_value_expression [ { , table_row_value_expression }... ]
 table_row_value_expression _maybe_comma_table_row_value_expression_multi
 ;
 
# Added
_maybe_comma_table_row_value_expression_multi:
 | | | | | | |
 , table_row_value_expression _maybe_comma_table_row_value_expression_multi
 ;

contextually_typed_table_value_constructor:
 VALUES contextually_typed_row_value_expression_list
 ;

# Modified
contextually_typed_row_value_expression_list:
# contextually_typed_row_value_expression [ { , contextually_typed_row_value_expression }... ]
 contextually_typed_row_value_expression _maybe_comma_contextually_typed_row_value_expression_multi
 ;
 
# Added
_maybe_comma_contextually_typed_row_value_expression_multi:
 | | | | | |
 , contextually_typed_row_value_expression _maybe_comma_contextually_typed_row_value_expression_multi
 ;

# Modified
table_expression:
# from_clause [ where_clause ] [ group_by_clause ] [ having_clause ] [ window_clause ]
 from_clause _maybe_where_clause _maybe_group_by_clause _maybe_having_clause _maybe_window_clause 
 ;
 
# Added
_maybe_where_clause:
 | where_clause
 ;
 
# Added
_maybe_group_by_clause:
 | group_by_clause
 ;
 
# Added
_maybe_having_clause:
 | having_clause
 ;
 
# Added
_maybe_window_clause:
 | window_clause
 ;

from_clause:
 FROM table_reference_list
 ;

# Modified
table_reference_list:
# table_reference [ { , table_reference }... ]
 table_reference _maybe_comma_table_reference_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_table_reference_multi:
 | | | | | | | |
 , table_reference _maybe_comma_table_reference_multi
 ;

# Modified probabilities
table_reference:
   table_factor 
 | table_factor 
 | table_factor 
 | table_factor 
 | table_factor 
 | table_factor 
 | joined_table
 ;

# Modified
table_factor:
# table_primary [ sample_clause ]
 table_primary _maybe_sample_clause
 ;

# Added
# Modified probabilities
_maybe_sample_clause:
 | | | | | | |
# Not supported (exists in PostreSQL)
# sample_clause
 ;
 
# Modified
sample_clause:
# tablesample sample_method ( sample_percentage ) [ repeatable_clause ]
 TABLESAMPLE sample_method ( sample_percentage ) _maybe_repeatable_clause
 ;

# Added
_maybe_repeatable_clause:
 | repeatable_clause
 ;
 
sample_method:
 BERNOULLI | SYSTEM
 ;

repeatable_clause:
 REPEATABLE ( repeat_argument ) ;

sample_percentage:
 numeric_value_expression
 ;

repeat_argument:
 numeric_value_expression
 ;

# Modified 
# Modified probabilities
table_primary:
# table_or_query_name [ query_system_time_period_specification ] [ [ as ] correlation_name [ ( derived_column_list ) ] ] | derived_table [ as ] correlation_name [ ( derived_column_list ) ] | lateral_derived_table [ as ] correlation_name [ ( derived_column_list ) ] | collection_derived_table [ as ] correlation_name [ ( derived_column_list ) ] | table_function_derived_table [ as ] correlation_name [ ( derived_column_list ) ] | only_spec [ [ as ] correlation_name [ ( derived_column_list ) ] ] | data_change_delta_table [ [ as ] correlation_name [ ( derived_column_list ) ] ] | parenthesized_joined_table
   table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | table_or_query_name _maybe_query_system_time_period_specification _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | derived_table _maybe_as correlation_name _maybe_left_paren_derived_column_list_right_paren 
# Not supported
# | lateral_derived_table _maybe_as correlation_name _maybe_left_paren_derived_column_list_right_paren 
# Not supported
# | collection_derived_table _maybe_as correlation_name _maybe_left_paren_derived_column_list_right_paren 
# Not supported
# | table_function_derived_table _maybe_as correlation_name _maybe_left_paren_derived_column_list_right_paren 
# Not supported
# | only_spec _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
# Not supported
# | data_change_delta_table _maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren 
 | parenthesized_joined_table
 ;

# Added
# Modified probabilities
_maybe_query_system_time_period_specification:
 | | | | | | |
# Not supported
# query_system_time_period_specification
 ;
 
# Added
# Modified probabilities
_maybe_maybe_as_correlation_name_maybe_left_paren_derived_column_list_right_paren:
 | | | | | | |
 _maybe_as correlation_name _maybe_left_paren_derived_column_list_right_paren
 ;
 
_maybe_as:
 | AS
 ;
 
_maybe_left_paren_derived_column_list_right_paren:
 | 
# Not supported
# ( derived_column_list ) 
 ;
 
# Not supported
query_system_time_period_specification:
   FOR SYSTEM_TIME AS OF point_in_time_1 
 | FOR SYSTEM_TIME BETWEEN _maybe_asymmetric_or_symmetric point_in_time_1 AND point_in_time_2 
 | FOR SYSTEM_TIME FROM point_in_time_1 TO point_in_time_2
 ;

point_in_time_1:
 point_in_time
 ;

point_in_time_2:
 point_in_time
 ;

point_in_time:
 datetime_value_expression
 ;

# Not supported
only_spec:
 ONLY ( table_or_query_name ) ;

# Not supported
lateral_derived_table:
 LATERAL table_subquery
 ;

# Modified
# Not supported (works in PostgreSQL)
collection_derived_table:
# unnest ( collection_value_expression [ { , collection_value_expression }... ] ) [ with ordinality ]
 UNNEST ( collection_value_expression _maybe_comma_collection_value_expression_multi ) _maybe_with_ordinality
 ;

# Added 
_maybe_comma_collection_value_expression_multi:
 | | | | | |
 , collection_value_expression _maybe_comma_collection_value_expression_multi
 ;
 
_maybe_with_ordinality:
 | | | 
 with ordinality
 ;

# Not supported
table_function_derived_table:
 TABLE ( collection_value_expression ) ;

derived_table:
 table_subquery
 ;

# Modified probabilities
table_or_query_name:
   table_name 
 | table_name 
 | table_name 
 | table_name 
 | table_name 
 | table_name 
 | table_name 
 | transition_table_name 
 | query_name
 ;

derived_column_list:
 column_name_list
 ;

# Modified
column_name_list:
# column_name [ { , column_name }... ]
 column_name _maybe_comma_column_name_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_column_name_multi:
 | | | | | | 
 , column_name _maybe_comma_column_name_multi
 ;

# Not supported
data_change_delta_table:
 result_option TABLE ( data_change_statement ) ;

data_change_statement:
 delete_statement__searched | insert_statement | merge_statement | update_statement__searched
 ;

result_option:
 FINAL | NEW | OLD
 ;

parenthesized_joined_table:
 ( parenthesized_joined_table ) | ( joined_table ) ;

joined_table:
 cross_join | qualified_join | natural_join
 ;

cross_join:
 table_reference CROSS JOIN table_factor
 ;

# Modified
qualified_join:
# { table_reference | partitioned_join_table } [ join_type ] JOIN { table_reference | partitioned_join_table } join_specification
 _table_reference_or_partitioned_join_table _maybe_join_type JOIN _table_reference_or_partitioned_join_table join_specification
 ;

# Added
# Modified probabilities
_table_reference_or_partitioned_join_table:
   table_reference 
 | table_reference
 | table_reference
 | table_reference
 | table_reference
 | table_reference
 | partitioned_join_table 
 ;
 
# Added
# Modified probabilities
_maybe_join_type:
 | | | | 
 join_type
 ;
 
partitioned_join_table:
 table_factor PARTITION BY partitioned_join_column_reference_list
 ;

# Modified
partitioned_join_column_reference_list:
# ( partitioned_join_column_reference [ { , partitioned_join_column_reference }... ] ) 
 ( partitioned_join_column_reference _maybe_comma_partitioned_join_column_reference_multi ) 
 ;
 
# Added
# Modified probabilities
_maybe_comma_partitioned_join_column_reference_multi:
 | | | | | 
 , partitioned_join_column_reference _maybe_comma_partitioned_join_column_reference_multi
 ;

partitioned_join_column_reference:
 column_reference
 ;

# Modified
natural_join:
# { table_reference | partitioned_join_table } natural [ join_type ] JOIN { table_factor | partitioned_join_table }
 _table_reference_or_partitioned_join_table natural _maybe_join_type JOIN _table_factor_or_partitioned_join_table
 ;
 
# Added
_table_factor_or_partitioned_join_table:
 table_factor | partitioned_join_table
 ;

join_specification:
 join_condition | named_columns_join
 ;

join_condition:
 on search_condition
 ;

named_columns_join:
 USING( join_column_list ) ;

# Modified
join_type:
# inner | outer_join_type [ outer ]
 INNER | outer_join_type _maybe_outer
 ;
 
# Added
_maybe_outer:
 | OUTER
 ;

outer_join_type:
 LEFT | RIGHT
 ;

join_column_list:
 column_name_list
 ;

where_clause:
 WHERE search_condition
 ;

# Modified
group_by_clause:
# group by [ set_quantifier ] grouping_element_list
 GROUP BY _maybe_set_quantifier grouping_element_list
 ;
 
# Added
# Modified probabilities
_maybe_set_quantifier:
 | | | | | 
 set_quantifier
 ;

# Modified
grouping_element_list:
# grouping_element [ { , grouping_element }... ]
 grouping_element _maybe_comma_grouping_element_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_grouping_element_multi:
 | | | | | | 
 , grouping_element _maybe_comma_grouping_element_multi
 ;

grouping_element:
   ordinary_grouping_set
# Nut supported
# | rollup_list
# Not supported
# | cube_list
# Not supported
# | grouping_sets_specification
# Not supported
# | empty_grouping_set
 ;

ordinary_grouping_set:
 grouping_column_reference | ( grouping_column_reference_list ) ;

# Modified
grouping_column_reference:
# column_reference [ collate_clause ]
 column_reference _maybe_collate_clause
 ;

# Modified
grouping_column_reference_list:
# grouping_column_reference [ { , grouping_column_reference }... ]
 grouping_column_reference _maybe_comma_grouping_column_reference_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_grouping_column_reference_multi:
 | | | | | | |
 , grouping_column_reference _maybe_comma_grouping_column_reference_multi
 ;

# Not supported
rollup_list:
 ROLLUP( ordinary_grouping_set_list ) ;

# Modified
ordinary_grouping_set_list:
# ordinary_grouping_set [ { , ordinary_grouping_set }... ]
 ordinary_grouping_set _maybe_comma_ordinary_grouping_set_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_ordinary_grouping_set_multi:
 | | | | | | 
 , ordinary_grouping_set _maybe_comma_ordinary_grouping_set_multi
 ;

cube_list:
 CUBE( ordinary_grouping_set_list ) ;

# Not supported
grouping_sets_specification:
 GROUPING SETS ( grouping_set_list ) ;

# Modified
grouping_set_list:
# grouping_set [ { , grouping_set }... ]
 grouping_set _maybe_comma_grouping_set_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_grouping_set_multi:
 | | | | | | 
 , grouping_set _maybe_comma_grouping_set_multi
 ;

grouping_set:
   ordinary_grouping_set
# Not supported
# | rollup_list
# Not supported
# | cube_list
# Not supported
# | grouping_sets_specification
# Not supported
# | empty_grouping_set
 ;

# Not supported
empty_grouping_set:
 ( ) ;

having_clause:
 HAVING search_condition
 ;

window_clause:
 WINDOW window_definition_list
 ;

# Modified
window_definition_list:
# window_definition [ { , window_definition }... ]
 window_definition _maybe_comma_window_definition_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_window_definition_multi:
 | | | | | | 
 , window_definition _maybe_comma_window_definition_multi
 ;

window_definition:
 new_window_name AS window_specification
 ;

new_window_name:
 window_name
 ;

window_specification:
 ( window_specification_details ) ;

# Modified
window_specification_details:
# [ existing_window_name ] [ window_partition_clause ] [ window_order_clause ] [ window_frame_clause ]
 _maybe_existing_window_name _maybe_window_partition_clause _maybe_window_order_clause _maybe_window_frame_clause
 ;
 
# Added
# Modified probabilities
_maybe_existing_window_name:
 | | | | | 
 existing_window_name
 ;

# Added
# Modified probabilities
_maybe_window_partition_clause:
 | | | | 
 window_partition_clause
 ;

# Added
# Modified probabilities
_maybe_window_order_clause:
 | | | | 
 window_order_clause
 ;

# Added
# Modified probabilities
_maybe_window_frame_clause:
 | | | 
 window_frame_clause
 ;

existing_window_name:
 window_name
 ;

window_partition_clause:
 PARTITION BY window_partition_column_reference_list
 ;

# Modified
window_partition_column_reference_list:
# window_partition_column_reference [ { , window_partition_column_reference }... ]
 window_partition_column_reference _maybe_comma_window_partition_column_reference_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_window_partition_column_reference_multi:
 | | | | | | |
 , window_partition_column_reference _maybe_comma_window_partition_column_reference_multi
 ;

# Modified
window_partition_column_reference:
# column_reference [ collate_clause ]
 column_reference _maybe_collate_clause
 ;

window_order_clause:
 ORDER BY sort_specification_list
 ;

# Modified
window_frame_clause:
# window_frame_units window_frame_extent [ window_frame_exclusion ]
 window_frame_units window_frame_extent _maybe_window_frame_exclusion
 ;
 
# Added
# Modified probabilities
_maybe_window_frame_exclusion:
 | | | | 
 window_frame_exclusion
 ;

window_frame_units:
 ROWS | RANGE | GROUPS
 ;

window_frame_extent:
 window_frame_start | window_frame_between
 ;

window_frame_start:
 UNBOUNDED PRECEDING | window_frame_preceding | CURRENT ROW
 ;

window_frame_preceding:
 unsigned_value_specification preceding
 ;

window_frame_between:
 BETWEEN window_frame_bound_1 AND window_frame_bound_2
 ;

window_frame_bound_1:
 window_frame_bound
 ;

window_frame_bound_2:
 window_frame_bound
 ;

window_frame_bound:
 window_frame_start | UNBOUNDED FOLLOWING | window_frame_following
 ;

window_frame_following:
 unsigned_value_specification following
 ;

window_frame_exclusion:
 EXCLUDE CURRENT ROW | EXCLUDE GROUP | EXCLUDE TIES | EXCLUDE NO OTHERS
 ;

# Modified
query_specification:
# select [ set_quantifier ] select_list table_expression
 SELECT _maybe_set_quantifier select_list table_expression
 ;

# Modified
# Modified probabilities
select_list:
# * | select_sublist [ { , select_sublist }... ]
   * 
 | *
 | *
 | *
 | select_sublist _maybe_comma_select_sublist_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_select_sublist_multi:
 | | | | |
 , select_sublist _maybe_comma_select_sublist_multi
 ;

select_sublist:
   derived_column 
 | qualified_asterisk
 ;

qualified_asterisk:
 asterisked_identifier_chain . * | all_fields_reference
 ;

# Modified
asterisked_identifier_chain:
# asterisked_identifier [ { period asterisked_identifier }... ]
 asterisked_identifier _maybe_period_asterisked_identifier_multi
 ;
 
# Added
# Modified probabilities
_maybe_period_asterisked_identifier_multi:
 | | | | | | 
 . asterisked_identifier _maybe_period_asterisked_identifier_multi
 ;

asterisked_identifier:
 identifier
 ;

# Modified
derived_column:
# value_expression [ as_clause ]
 value_expression _maybe_as_clause
 ;
 
# Added
_maybe_as_clause:
 | as_clause
 ;

# Modified
as_clause:
# [ as ] column_name
 _maybe_as column_name
 ;

# Modified
all_fields_reference:
# value_expression_primary period * [ as ( all_fields_column_name_list ) ]
 value_expression_primary . * _maybe_as_left_paren_all_fields_column_name_list_right_paren
 ;
 
# Added
# Modified probabilities
_maybe_as_left_paren_all_fields_column_name_list_right_paren:
 | | | | | 
 AS ( all_fields_column_name_list ) ;

all_fields_column_name_list:
 column_name_list
 ;

# Modified
query_expression:
# [ with_clause ] query_expression_body [ order_by_clause ] [ result_offset_clause ] [ fetch_first_clause ]
 _maybe_with_clause query_expression_body _maybe_order_by_clause _maybe_result_offset_clause _maybe_fetch_first_clause
 ;
 
# Added
# Modified probabilities
_maybe_with_clause:
 | | | | | | | |
 with_clause
 ;

# Added
# Modified probabilities
_maybe_order_by_clause:
 | | | | 
 order_by_clause
 ;

# Added
# Modified probabilities
_maybe_result_offset_clause:
 | | | | |
 result_offset_clause
 ;

# Added
# Modified probabilities
_maybe_fetch_first_clause:
 | | | | | | | 
 fetch_first_clause
 ;

# Modified
with_clause:
# with [ recursive ] with_list
 WITH _maybe_recursive with_list
 ;

# Added
# Modified probabilities
_maybe_recursive:
 | | | |
 RECURSIVE
 ;

# Modified
with_list:
# with_list_element [ { , with_list_element }... ]
 with_list_element _maybe_comma_with_list_element_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_with_list_element_multi:
 | | | | | | | 
 , with_list_element _maybe_comma_with_list_element_multi
 ;

# Modified
with_list_element:
# query_name [ ( with_column_list ) ] as table_subquery [ search_or_cycle_clause ]
 query_name _maybe_left_paren_with_column_list_right_paren AS table_subquery _maybe_search_or_cycle_clause
 ;
 
# Added
# Modified probabilities
_maybe_left_paren_with_column_list_right_paren:
 | | | | | |
 ( with_column_list ) ;

# Added
# Modified probabilities
_maybe_search_or_cycle_clause:
 | | | | | 
 search_or_cycle_clause
 ;

with_column_list:
 column_name_list
 ;

# Modified
# Modified probabilities
query_expression_body:
# query_term | query_expression_body union [ all | distinct ] [ corresponding_spec ] query_term | query_expression_body except [ all | distinct ] [ corresponding_spec ] query_term
   query_term 
 | query_term
 | query_term
 | query_term
 | query_term
 | query_term
 | query_expression_body UNION _maybe_all_or_distinct _maybe_corresponding_spec query_term 
 | query_expression_body EXCEPT _maybe_all_or_distinct _maybe_corresponding_spec query_term
 ;

# Added
# Modified probabilities
_maybe_corresponding_spec:
 | | | | | 
 corresponding_spec
 ;
 
# Modified
# Modified probabilities
query_term:
# query_primary | query_term intersect [ all | distinct ] [ corresponding_spec ] query_primary
   query_primary 
 | query_primary
 | query_primary
 | query_primary
 | query_primary
 | query_primary
 | query_term INTERSECT _maybe_all_or_distinct _maybe_corresponding_spec query_primary
 ;

# Modified
# Modified probabilities
query_primary:
# simple_table | ( query_expression_body [ order_by_clause ] [ result_offset_clause ] [ fetch_first_clause ] ) 
   simple_table
 | simple_table
 | simple_table
 | simple_table
 | simple_table
 | simple_table
 | simple_table
 | ( query_expression_body _maybe_order_by_clause _maybe_result_offset_clause _maybe_fetch_first_clause ) ;

# Modified probabilities
simple_table:
   query_specification 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
 | table_value_constructor 
# Not supported
# | explicit_table
 ;

# Not supported (works in PostgreSQL)
explicit_table:
 TABLE table_or_query_name
 ;

# Modified
corresponding_spec:
# corresponding [ by ( corresponding_column_list ) ]
 corresponding _maybe_by_left_paren_corresponding_column_list_right_paren
 ;
 
# Added
# Modified probabilities
_maybe_by_left_paren_corresponding_column_list_right_paren:
 | | | | | 
 BY ( corresponding_column_list ) ;

corresponding_column_list:
 column_name_list
 ;

order_by_clause:
 ORDER BY sort_specification_list
 ;

# Modified
result_offset_clause:
# offset offset_row_count { row | rows }
 offset offset_row_count _row_or_rows
 ;
 
# Added
_row_or_rows:
 ROW | ROWS
 ;

# Modified
fetch_first_clause:
# fetch { first | next } [ fetch_first_quantity ] { row | rows } { only | with ties }
 fetch _first_or_next _maybe_fetch_first_quantity _row_or_rows _only_or_with_ties
 ;
 
# Added
_first_or_next:
 FIRST | NEXT
 ;
 
# Added
# Modified probabilities
_maybe_fetch_first_quantity:
 | | | | |
 fetch_first_quantity
 ;
 
# Added
_only_or_with_ties:
 only | with ties
 ;

fetch_first_quantity:
 fetch_first_row_count | fetch_first_percentage
 ;

offset_row_count:
 simple_value_specification
 ;

fetch_first_row_count:
 simple_value_specification
 ;

fetch_first_percentage:
 simple_value_specification %
 ;

search_or_cycle_clause:
 search_clause | cycle_clause | search_clause cycle_clause
 ;

search_clause:
 search recursive_search_order set sequence_column
 ;

recursive_search_order:
 depth first by column_name_list | breadth first by column_name_list
 ;

sequence_column:
 column_name
 ;

cycle_clause:
 cycle cycle_column_list set cycle_mark_column TO cycle_mark_value default non_cycle_mark_value USING path_column
 ;

# Modified
cycle_column_list:
# cycle_column [ { , cycle_column }... ]
 cycle_column _maybe_comma_cycle_column_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_cycle_column_multi:
 | | | | | |
 , cycle_column _maybe_comma_cycle_column_multi
 ;

cycle_column:
 column_name
 ;

cycle_mark_column:
 column_name
 ;

path_column:
 column_name
 ;

cycle_mark_value:
 value_expression
 ;

non_cycle_mark_value:
 value_expression
 ;

scalar_subquery:
 subquery
 ;

row_subquery:
 subquery
 ;

table_subquery:
 subquery
 ;

subquery:
 ( query_expression ) ;

predicate:
   comparison_predicate
 | between_predicate
 | in_predicate
 | like_predicate
 | similar_predicate
 | regex_like_predicate
 | null_predicate
 | quantified_comparison_predicate
 | exists_predicate
# Not supported
# | unique_predicate
 | normalized_predicate
 | match_predicate
# Not supported
# | overlaps_predicate
 | distinct_predicate
 | member_predicate
 | submultiset_predicate
 | set_predicate
 | type_predicate
# Not supported
# | period_predicate
 ;

comparison_predicate:
 row_value_predicand comparison_predicate_part_2
 ;

comparison_predicate_part_2:
 comp_op row_value_predicand
 ;

comp_op:
 equals_operator | not_equals_operator | less_than_operator | greater_than_operator | less_than_or_equals_operator | greater_than_or_equals_operator
 ;

between_predicate:
 row_value_predicand between_predicate_part_2
 ;

# Modified
between_predicate_part_2:
# [ not ] between [ asymmetric | symmetric ] row_value_predicand and row_value_predicand
 _maybe_not BETWEEN _maybe_asymmetric_or_symmetric row_value_predicand AND row_value_predicand
 ;
 
# Added
_maybe_asymmetric_or_symmetric:
 | ASYMMETRIC | SYMMETRIC
 ;

in_predicate:
 row_value_predicand in_predicate_part_2
 ;

# Modified
in_predicate_part_2:
# [ not ] in in_predicate_value
 _maybe_not IN in_predicate_value
 ;

in_predicate_value:
 table_subquery | ( in_value_list ) ;

# Modified
in_value_list:
# row_value_expression [ { , row_value_expression }... ]
 row_value_expression _maybe_comma_row_value_expression_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_row_value_expression_multi:
 | | | | | 
 , row_value_expression _maybe_comma_row_value_expression_multi
 ;
 
like_predicate:
 character_like_predicate | octet_like_predicate
 ;

character_like_predicate:
 row_value_predicand character_like_predicate_part_2
 ;

# Modified
character_like_predicate_part_2:
# [ not ] like character_pattern [ escape escape_character ]
 _maybe_not like character_pattern _maybe_escape_escape_character
 ;
 
# Added
# Modified probabilities
_maybe_escape_escape_character:
 | | | | | | 
 escape escape_character
 ;

character_pattern:
 character_value_expression
 ;

escape_character:
 character_value_expression
 ;

octet_like_predicate:
 row_value_predicand octet_like_predicate_part_2
 ;

# Modified
octet_like_predicate_part_2:
# [ not ] like octet_pattern [ escape escape_octet ]
 _maybe_not like octet_pattern _maybe_escape_escape_octet
 ;
 
# Added
# Modified probabilities
_maybe_escape_escape_octet:
 | | | | | | | 
 escape escape_octet
 ;

octet_pattern:
 binary_value_expression
 ;

escape_octet:
 binary_value_expression
 ;

similar_predicate:
 row_value_predicand similar_predicate_part_2
 ;

# Modified
similar_predicate_part_2:
# [ not ] similar TO similar_pattern [ escape escape_character ]
 _maybe_not similar TO similar_pattern _maybe_escape_escape_character
 ;

similar_pattern:
 character_value_expression
 ;

regular_expression:
 regular_term | regular_expression vertical_bar regular_term
 ;

regular_term:
 regular_factor | regular_term regular_factor
 ;

regular_factor:
 regular_primary | regular_primary * | regular_primary + | regular_primary question_mark | regular_primary repeat_factor
 ;

# Modified
repeat_factor:
# left_brace low_value [ upper_limit ] right_brace
 left_brace low_value _maybe_upper_limit right_brace
 ;
 
# Added
_maybe_upper_limit:
 | upper_limit
 ;

# Modified
upper_limit:
# , [ high_value ]
 , _maybe_high_value
 ;
 
# Added
_maybe_high_value:
 | high_value
 ;

low_value:
 unsigned_integer
 ;

high_value:
 unsigned_integer
 ;

regular_primary:
 character_specifier | % | regular_character_set | ( regular_expression ) ;

character_specifier:
 non_escaped_character | escaped_character
 ;

# TODO
# Heavily modified
non_escaped_character:
 # see the syntax rules.
 simple_latin_letter
 ;

# TODO
# Heavily modified
escaped_character:
 # see the syntax rules.
 simple_latin_letter
 ;

# Modified
regular_character_set:
# underscore | [ character_enumeration... ] | [ circumflex character_enumeration... ] | [ character_enumeration_include... circumflex character_enumeration_exclude... right_bracket
 underscore | [ _character_enumeration_multi ] | [ circumflex _character_enumeration_multi ] | [ _character_enumeration_include_multi circumflex _character_enumeration_exclude_multi right_bracket
 ;

# Added
_character_enumeration_multi:
   character_enumeration
 | character_enumeration
 | character_enumeration
 | character_enumeration
 | character_enumeration
 | character_enumeration _character_enumeration_multi
 ;
 
# Added
_character_enumeration_include_multi:
   character_enumeration_include
 | character_enumeration_include
 | character_enumeration_include
 | character_enumeration_include
 | character_enumeration_include
 | character_enumeration_include _character_enumeration_include_multi
 ;
 
# Added
_character_enumeration_exclude_multi:
   character_enumeration_exclude
 | character_enumeration_exclude
 | character_enumeration_exclude
 | character_enumeration_exclude
 | character_enumeration_exclude
 | character_enumeration_exclude _character_enumeration_exclude_multi
 ;
 
character_enumeration_include:
 character_enumeration
 ;

character_enumeration_exclude:
 character_enumeration
 ;

character_enumeration:
 character_specifier | character_specifier - character_specifier | [:regular_character_set_identifier:]
 ;

regular_character_set_identifier:
 identifier
 ;

regex_like_predicate:
 row_value_predicand regex_like_predicate_part_2
 ;

# Modified
regex_like_predicate_part_2:
# [ not ] like_regex xquery_pattern [ flag xquery_option_flag ]
 _maybe_not like_regex xquery_pattern _maybe_flag_xquery_option_flag
 ;

null_predicate:
 row_value_predicand null_predicate_part_2
 ;

# Modified
null_predicate_part_2:
# is [ not ] null
 IS _maybe_not NULL
 ;

quantified_comparison_predicate:
 row_value_predicand quantified_comparison_predicate_part_2
 ;

quantified_comparison_predicate_part_2:
 comp_op quantifier table_subquery
 ;

quantifier:
 all | some
 ;

all:
 ALL
 ;

some:
 SOME | ANY
 ;

exists_predicate:
 EXISTS table_subquery
 ;

# Not supported
unique_predicate:
 UNIQUE table_subquery
 ;

normalized_predicate:
 row_value_predicand normalized_predicate_part_2
 ;

# Modified
normalized_predicate_part_2:
# is [ not ] [ normal_form ] normalized
 IS _maybe_not _maybe_normal_form normalized
 ;
 
# Modified
# Modified probabilities
_maybe_normal_form:
 | | | | | 
 normal_form
 ;

match_predicate:
 row_value_predicand match_predicate_part_2
 ;

# Modified
match_predicate_part_2:
# match [ unique ] [ simple | partial | full ] table_subquery
 MATCH _maybe_unique _maybe_simple_or_partial_or_full table_subquery
 ;
 
# Added
# Modified probabilities
_maybe_unique:
 | | | 
 UNIQUE
 ;
 
# Added
_maybe_simple_or_partial_or_full:
 | SIMPLE | PARTIAL | FULL
 ;

# Not supported
overlaps_predicate:
 overlaps_predicate_part_1 overlaps_predicate_part_2
 ;

# Not supported
overlaps_predicate_part_1:
 row_value_predicand_1
 ;

# Not supported
overlaps_predicate_part_2:
 OVERLAPS row_value_predicand_2
 ;

row_value_predicand_1:
 row_value_predicand
 ;

row_value_predicand_2:
 row_value_predicand
 ;

distinct_predicate:
 row_value_predicand_3 distinct_predicate_part_2
 ;

# Modified
distinct_predicate_part_2:
# is [ not ] distinct from row_value_predicand_4
 IS _maybe_not DISTINCT FROM row_value_predicand_4
 ;

row_value_predicand_3:
 row_value_predicand
 ;

row_value_predicand_4:
 row_value_predicand
 ;

member_predicate:
 row_value_predicand member_predicate_part_2
 ;

# Modified
member_predicate_part_2:
# [ not ] member [ of ] multiset_value_expression
 _maybe_not member _maybe_of multiset_value_expression
 ;

# Added
_maybe_of:
 | OF 
 ;
 
submultiset_predicate:
 row_value_predicand submultiset_predicate_part_2
 ;

# Modified
submultiset_predicate_part_2:
# [ not ] submultiset [ of ] multiset_value_expression
 _maybe_not submultiset _maybe_of multiset_value_expression
 ;

set_predicate:
 row_value_predicand set_predicate_part_2
 ;

# Modified
set_predicate_part_2:
# is [ not ] a set
 IS _maybe_not A SET
 ;

type_predicate:
 row_value_predicand type_predicate_part_2
 ;

# Modified
type_predicate_part_2:
# is [ not ] of ( type_list ) 
 IS _maybe_not of ( type_list ) ;

# Modified
type_list:
# user_defined_type_specification [ { , user_defined_type_specification }... ]
 user_defined_type_specification _maybe_comma_user_defined_type_specification_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_user_defined_type_specification_multi:
 | | | | | | |
 , user_defined_type_specification _maybe_comma_user_defined_type_specification_multi
 ;

user_defined_type_specification:
 inclusive_user_defined_type_specification | exclusive_user_defined_type_specification
 ;

inclusive_user_defined_type_specification:
 path_resolved_user_defined_type_name
 ;

exclusive_user_defined_type_specification:
 only path_resolved_user_defined_type_name
 ;

# Not supported
period_predicate:
 period_overlaps_predicate | period_equals_predicate | period_contains_predicate | period_precedes_predicate | period_succeeds_predicate | period_immediately_precedes_predicate | period_immediately_succeeds_predicate
 ;

period_overlaps_predicate:
 period_predicand_1 period_overlaps_predicate_part_2
 ;

period_overlaps_predicate_part_2:
 overlaps period_predicand_2
 ;

period_predicand_1:
 period_predicand
 ;

period_predicand_2:
 period_predicand
 ;

period_predicand:
 period_reference | PERIOD ( period_start_value , period_end_value ) ;

period_reference:
 basic_identifier_chain
 ;

period_start_value:
 datetime_value_expression
 ;

period_end_value:
 datetime_value_expression
 ;

period_equals_predicate:
 period_predicand_1 period_equals_predicate_part_2
 ;

period_equals_predicate_part_2:
 equals period_predicand_2
 ;

period_contains_predicate:
 period_predicand_1 period_contains_predicate_part_2
 ;

period_contains_predicate_part_2:
 contains period_or_point_in_time_predicand
 ;

period_or_point_in_time_predicand:
 period_predicand | datetime_value_expression
 ;

period_precedes_predicate:
 period_predicand_1 period_precedes_predicate_part_2
 ;

period_precedes_predicate_part_2:
 precedes period_predicand_2
 ;

period_succeeds_predicate:
 period_predicand_1 period_succeeds_predicate_part_2
 ;

period_succeeds_predicate_part_2:
 succeeds period_predicand_2
 ;

period_immediately_precedes_predicate:
 period_predicand_1 period_immediately_precedes_predicate_part_2
 ;

period_immediately_precedes_predicate_part_2:
 immediately precedes period_predicand_2
 ;

period_immediately_succeeds_predicate:
 period_predicand_1 period_immediately_succeeds_predicate_part_2
 ;

period_immediately_succeeds_predicate_part_2:
 immediately succeeds period_predicand_2
 ;

search_condition:
 boolean_value_expression
 ;

interval_qualifier:
 start_field TO end_field | single_datetime_field
 ;

# Modified
start_field:
# non_second_primary_datetime_field [ ( interval_leading_field_precision ) ]
 non_second_primary_datetime_field _maybe_left_paren_interval_leading_field_precision_right_paren
 ;
 
# Added
# Modified probabilities
_maybe_left_paren_interval_leading_field_precision_right_paren:
 | | | | | |
 ( interval_leading_field_precision ) 
 ;

# Modified
end_field:
# non_second_primary_datetime_field | second [ ( interval_fractional_seconds_precision ) ]
 non_second_primary_datetime_field | second _maybe_left_paren_interval_fractional_seconds_precision_right_paren
 ;
 
# Added
# Modified probabilities
_maybe_left_paren_interval_fractional_seconds_precision_right_paren:
 | | | | | | 
 ( interval_fractional_seconds_precision ) 
 ;

# Modified
single_datetime_field:
# non_second_primary_datetime_field [ ( interval_leading_field_precision ) ] | second [ ( interval_leading_field_precision [ , interval_fractional_seconds_precision ] ) ]
 non_second_primary_datetime_field _maybe_left_paren_interval_leading_field_precision_right_paren | second _maybe_left_paren_interval_leading_field_precision_maybe_comma_interval_fractional_seconds_precision_right_paren
 ;
 
# Added
_# Modified probabilities
maybe_left_paren_interval_leading_field_precision_maybe_comma_interval_fractional_seconds_precision_right_paren:
 | | | | | |
 ( interval_leading_field_precision _maybe_comma_interval_fractional_seconds_precision ) ;
 
# Added
# Modified probabilities
_maybe_comma_interval_fractional_seconds_precision:
 | | | | | |
 , interval_fractional_seconds_precision
 ;

primary_datetime_field:
 non_second_primary_datetime_field | second
 ;

non_second_primary_datetime_field:
 YEAR | MONTH | DAY | HOUR | MINUTE
 ;

interval_fractional_seconds_precision:
 unsigned_integer
 ;

interval_leading_field_precision:
 unsigned_integer
 ;

language_clause:
 language language_name
 ;

language_name:
 ADA | C | COBOL | FORTRAN | M | MUMPS | PASCAL | PLI | SQL
 ;

path_specification:
 path schema_name_list
 ;

# Modified
schema_name_list:
# schema_name [ { , schema_name }... ]
 schema_name _maybe_comma_schema_name_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_schema_name_multi:
 | | | | 
 , schema_name _maybe_comma_schema_name_multi
 ;

routine_invocation:
 routine_name sql_argument_list
 ;

# Modified
routine_name:
# [ schema_name period ] qualified_identifier
 _maybe_schema_name_period qualified_identifier
 ;

# Modified
sql_argument_list:
# ( [ sql_argument [ { , sql_argument }... ] ] ) 
 ( _maybe_sql_argument_maybe_comma_sql_argument_multi ) 
 ;
 
# Added
# Modified probabilities
_maybe_sql_argument_maybe_comma_sql_argument_multi:
 | | | | | 
 sql_argument _maybe_comma_sql_argument_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_sql_argument_multi:
 | | | | | | 
 , sql_argument _maybe_comma_sql_argument_multi
 ;

sql_argument:
 value_expression | generalized_expression | target_specification | contextually_typed_value_specification | named_argument_specification
 ;

generalized_expression:
 value_expression AS path_resolved_user_defined_type_name
 ;

named_argument_specification:
 sql_parameter_name named_argument_assignment_token named_argument_sql_argument
 ;

named_argument_sql_argument:
 value_expression | target_specification
 ;

character_set_specification:
 standard_character_set_name | implementation_defined_character_set_name | user_defined_character_set_name
 ;

standard_character_set_name:
 character_set_name
 ;

implementation_defined_character_set_name:
 character_set_name
 ;

user_defined_character_set_name:
 character_set_name
 ;

# Modified
specific_routine_designator:
# specific routine_type specific_name | routine_type member_name [ FOR schema_resolved_user_defined_type_name ]
 specific routine_type specific_name | routine_type member_name _maybe_for_schema_resolved_user_defined_type_name
 ;
 
# Added
# Modified probabilities
_maybe_for_schema_resolved_user_defined_type_name:
 | | | | 
 FOR schema_resolved_user_defined_type_name
 ;

# Modified
routine_type:
# routine | function | procedure | [ instance | static | constructor ] method
 ROUTINE | FUNCTION | PROCEDURE | _maybe_instance_or_static_or_constructor METHOD
 ;
 
# Added
_maybe_instance_or_static_or_constructor:
 | INSTANCE | STATIC | CONSTRUCTOR 
 ;

# Modified
member_name:
# member_name_alternatives [ data_type_list ]
 member_name_alternatives _maybe_data_type_list
 ;
 
# Added
# Modified probabilities
_maybe_data_type_list:
 | | | | | 
 data_type_list
 ;

member_name_alternatives:
 schema_qualified_routine_name | method_name
 ;

# Modified
data_type_list:
# ( [ data_type [ { , data_type }... ] ] ) 
  ( _maybe_data_type_maybe_comma_data_type_multi ) ;
 
# Added
# Modified probabilities
_maybe_data_type_maybe_comma_data_type_multi:
 | | | | | |
 data_type _maybe_comma_data_type_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_data_type_multi:
 | | | | | | 
 , data_type _maybe_comma_data_type_multi
 ;

collate_clause:
 COLLATE collation_name
 ;

constraint_name_definition:
 constraint constraint_name
 ;

# Modified
constraint_characteristics:
# constraint_check_time [ [ not ] deferrable ] [ constraint_enforcement ] | [ not ] deferrable [ constraint_check_time ] [ constraint_enforcement ] | constraint_enforcement
 constraint_check_time _maybe_maybe_not_deferrable _maybe_constraint_enforcement | _maybe_not deferrable _maybe_constraint_check_time _maybe_constraint_enforcement | constraint_enforcement
 ;
 
# Added
# Modified probabilities
_maybe_constraint_check_time:
 | | | | | 
 constraint_check_time
 ;
 
# Added
_maybe_maybe_not_deferrable:
 | _maybe_not DEFERRABLE
 ;
 
# Added
_maybe_constraint_enforcement:
 | constraint_enforcement
 ;

constraint_check_time:
 initially deferred | initially immediate
 ;

# Modified
constraint_enforcement:
# [ not ] enforced
 _maybe_not ENFORCED
 ;

# Modified
aggregate_function:
# count ( * ) [ filter_clause ] | general_set_function [ filter_clause ] | binary_set_function [ filter_clause ] | ordered_set_function [ filter_clause ] | array_aggregate_function [ filter_clause ]
   COUNT( * ) _maybe_filter_clause
 | general_set_function _maybe_filter_clause
 | binary_set_function _maybe_filter_clause
 | ordered_set_function _maybe_filter_clause
# Not supported
# | array_aggregate_function _maybe_filter_clause
 ;

# Modified probabilities
_maybe_filter_clause:
 | | | | | |
# Not supported
# filter_clause
 ;
 
# Modified
general_set_function:
# set_function_type ( [ set_quantifier ] value_expression ) 
 set_function_type ( _maybe_set_quantifier value_expression ) ;

set_function_type:
 computational_operation
 ;

computational_operation:
   AVG 
 | MAX 
 | MIN 
 | SUM 
 | EVERY 
 | ANY 
 | SOME 
 | COUNT 
 | STDDEV_POP 
 | STDDEV_SAMP 
 | VAR_SAMP 
 | VAR_POP 
 | COLLECT 
 | FUSION 
 | INTERSECTION
 ;

set_quantifier:
 DISTINCT | ALL
 ;

# Not supported
filter_clause:
 FILTER ( WHERE search_condition ) ;

binary_set_function:
 binary_set_function_type ( dependent_variable_expression , independent_variable_expression ) ;

binary_set_function_type:
   COVAR_POP 
 | COVAR_SAMP
 | CORR 
 | REGR_SLOPE 
 | REGR_INTERCEPT 
 | REGR_COUNT 
 | REGR_R2 
 | REGR_AVGX 
 | REGR_AVGY 
 | REGR_SXX 
 | REGR_SYY 
 | REGR_SXY
 ;

dependent_variable_expression:
 numeric_value_expression
 ;

independent_variable_expression:
 numeric_value_expression
 ;

ordered_set_function:
 hypothetical_set_function | inverse_distribution_function
 ;

hypothetical_set_function:
 rank_function_type ( hypothetical_set_function_value_expression_list ) within_group_specification
 ;

within_group_specification:
 WITHIN GROUP ( ORDER BY sort_specification_list ) ;

# Modified
hypothetical_set_function_value_expression_list:
# value_expression [ { , value_expression }... ]
 value_expression _maybe_comma_value_expression_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_value_expression_multi:
 | | | | | | | 
 , value_expression _maybe_comma_value_expression_multi
 ;

inverse_distribution_function:
 inverse_distribution_function_type ( inverse_distribution_function_argument ) within_group_specification
 ;

inverse_distribution_function_argument:
 numeric_value_expression
 ;

inverse_distribution_function_type:
   PERCENTILE_CONT 
 | PERCENTILE_DISC
 ;

# Modified
# Not supported
array_aggregate_function:
# array_agg ( value_expression [ ORDER BY sort_specification_list ] ) 
 ARRAY_AGG( value_expression _maybe_order_by_sort_specification_list ) ;
 
# Added
# Modified probabilities
_maybe_order_by_sort_specification_list:
 | | | | | | | 
 ORDER BY sort_specification_list
 ;

# Modified
sort_specification_list:
# sort_specification [ { , sort_specification }... ]
 sort_specification _maybe_comma_sort_specification_multi
 ;
 
# Added
# Modified probabilities
_maybe_comma_sort_specification_multi:
 | | | | | | 
 , sort_specification _maybe_comma_sort_specification_multi
 ;

# Modified
sort_specification:
# sort_key [ ordering_specification ] [ null_ordering ]
 sort_key _maybe_ordering_specification _maybe_null_ordering
 ;
 
# Modified probabilities
_maybe_ordering_specification:
 | | | | | 
 ordering_specification
 ;
 
_maybe_null_ordering:
 |
# Not supported
# null_ordering
 ;

sort_key:
 value_expression
 ;

ordering_specification:
 ASC | DESC
 ;

null_ordering:
 NULLS FIRST | NULLS LAST
 ;

# Modified
schema_definition:
# create schema schema_name_clause [ schema_character_set_or_path ] [ schema_element... ]
 create schema schema_name_clause _maybe_schema_character_set_or_path _maybe_schema_element_multi
 ;
 
# Added
# Modified probabilities
_maybe_schema_element_multi:
 | | | | | 
 schema_element _maybe_schema_element_multi
 ;
 
# Added
# Modified probabilities
_maybe_schema_character_set_or_path:
 | | | | 
 schema_character_set_or_path
 ;

schema_character_set_or_path:
 schema_character_set_specification | schema_path_specification | schema_character_set_specification schema_path_specification | schema_path_specification schema_character_set_specification
 ;

schema_name_clause:
 schema_name | authorization schema_authorization_identifier | schema_name authorization schema_authorization_identifier
 ;

schema_authorization_identifier:
 authorization_identifier
 ;

schema_character_set_specification:
 default character set character_set_specification
 ;

schema_path_specification:
 path_specification
 ;

schema_element:
 table_definition | view_definition | domain_definition | character_set_definition | collation_definition | transliteration_definition | assertion_definition | trigger_definition | user_defined_type_definition
 ;

drop_schema_statement:
 drop schema schema_name drop_behavior
 ;

drop_behavior:
 CASCADE | RESTRICT
 ;

# Modified
table_definition:
# create [ table_scope ] TABLE table_name table_contents_source [ with system_versioning_clause ] [ on commit table_commit_action rows ]
 create _maybe_table_scope TABLE table_name table_contents_source _maybe_with_system_versioning_clause _maybe_on_commit_table_commit_action_rows
 ;
 
# Added
# Modified probabilities
_maybe_on_commit_table_commit_action_rows:
 | | | 
 ON COMMIT table_commit_action rows
 ;
 
# Added
# Modified probabilities
_maybe_with_system_versioning_clause:
 | | | 
 WITH system_versioning_clause
 ;
 
# Added
# Modified probabilities
_maybe_table_scope:
 | | | | 
 table_scope
 ;

table_contents_source:
 table_element_list | typed_table_clause | as_subquery_clause
 ;

table_scope:
 global_or_local temporary
 ;

global_or_local:
 GLOBAL | LOCAL
 ;

system_versioning_clause:
 SYSTEM VERSIONING
 ;

table_commit_action:
   PRESERVE 
 | DELETE
 ;

# Modified
table_element_list:
# ( table_element [ { , table_element }... ] ) 
 ( table_element _maybe_comma_table_element_multi ) ;
 
# Added
# Modified probabilities
_maybe_comma_table_element_multi:
 | | | | | | 
 , table_element _maybe_comma_table_element_multi
 ;

table_element:
   column_definition
# Not supported
# | table_period_definition
 | table_constraint_definition
 | like_clause
 ;

# Modified
typed_table_clause:
# of path_resolved_user_defined_type_name [ subtable_clause ] [ typed_table_element_list ]
 of path_resolved_user_defined_type_name _maybe_subtable_clause _maybe_typed_table_element_list
 ;

# Added:
# Modified probabilities
_maybe_typed_table_element_list:
 | | | 
 typed_table_element_list
 ;
 
# Added 
# Modified probabilities
_maybe_subtable_clause:
 | | | | 
 subtable_clause
 ;

# Modified
typed_table_element_list:
# ( typed_table_element [ { , typed_table_element }... ] ) 
 ( typed_table_element _maybe_comma_typed_table_element_multi ) ;
 
# Added
# Modified probabilities
_maybe_comma_typed_table_element_multi:
 | | | | | 
 , table_typed_element _maybe_comma_typed_table_element_multi
 ;

typed_table_element:
 column_options
 ;

# Modified
# Not supported
self_referencing_column_specification:
# ref is self_referencing_column_name [ reference_generation ]
 REF IS self_referencing_column_name _maybe_reference_generation
 ;
 
# Added
_maybe_reference_generation:
 | reference_generation
 ;

reference_generation:
 system generated | user generated | derived
 ;

self_referencing_column_name:
 column_name
 ;

column_options:
 column_name with options column_option_list
 ;

# Modified
column_option_list:
# [ scope_clause ] [ default_clause ] [ column_constraint_definition... ]
 _maybe_scope_clause _maybe_default_clause _maybe_column_constraint_definition_multi
 ;
 
# Added
_maybe_column_constraint_definition_multi:
 | | | | |
 column_constraint_definition _maybe_column_constraint_definition_multi
 ;
 
# Added
_maybe_default_clause:
 | default_clause
 ;

subtable_clause:
 under supertable_clause
 ;

supertable_clause:
 supertable_name
 ;

supertable_name:
 table_name
 ;

# Modified
like_clause:
# like table_name [ like_options ]
 LIKE table_name _maybe_like_options
 ;
 
# Added
_maybe_like_options:
 | like_options
 ;

# Modified
like_options:
# like_option...
 _like_option_multi
 ;
 
# Added
_like_option_multi:
   like_option
 | like_option
 | like_option
 | like_option
 | like_option
 | like_option _like_option_multi
 ;

like_option:
 identity_option | column_default_option | generation_option
 ;

identity_option:
   INCLUDING IDENTITY 
 | EXCLUDING IDENTITY
 ;

column_default_option:
   INCLUDING DEFAULTS 
 | EXCLUDING DEFAULTS
 ;

generation_option:
   INCLUDING GENERATED 
 | EXCLUDING GENERATED
 ;

# Modified
as_subquery_clause:
# [ ( column_name_list ) ] as table_subquery with_or_without_data
 _maybe_left_paren_column_name_list_right_paren AS table_subquery with_or_without_data
 ;
 
# Added
_maybe_left_paren_column_name_list_right_paren:
 | ( column_name_list ) 
 ;

with_or_without_data:
   WITH NO DATA 
 | WITH DATA
 ;

# Not supported
table_period_definition:
 system_or_application_time_period_specification ( period_begin_column_name , period_end_column_name ) ;

# Not supported
system_or_application_time_period_specification:
   system_time_period_specification
 | application_time_period_specification
 ;

# Not supported
system_time_period_specification:
 PERIOD FOR SYSTEM_TIME
 ;

application_time_period_specification:
 PERIOD FOR application_time_period_name
 ;

application_time_period_name:
 identifier
 ;

period_begin_column_name:
 column_name
 ;

period_end_column_name:
 column_name
 ;

# Modified
column_definition:
# column_name [ data_type_or_domain_name ] [ default_clause | identity_column_specification | generation_clause | system_time_period_start_column_specification | system_time_period_end_column_specification ] [ column_constraint_definition... ] [ collate_clause ]
 column_name _maybe_data_type_or_domain_name _maybe_default_clause_or_identity_column_specification_or_generation_clause_or_system_time_period_start_column_specification_or_system_time_period_end_column_specification _maybe_column_constraint_definition_multi _maybe_collate_clause
 ;
 
# Added
_maybe_default_clause_or_identity_column_specification_or_generation_clause_or_system_time_period_start_column_specification_or_system_time_period_end_column_specification:
 | default_clause | identity_column_specification | generation_clause | system_time_period_start_column_specification | system_time_period_end_column_specification
 ;
 
# Added
_maybe_data_type_or_domain_name:
 | data_type_or_domain_name
 ;

data_type_or_domain_name:
 data_type | domain_name
 ;

system_time_period_start_column_specification:
 timestamp_generation_rule AS ROW start
 ;

system_time_period_end_column_specification:
 timestamp_generation_rule AS ROW end
 ;

timestamp_generation_rule:
 GENERATED ALWAYS
 ;

# Modified
column_constraint_definition:
# [ constraint_name_definition ] column_constraint [ constraint_characteristics ]
 _maybe_constraint_name_definition column_constraint _maybe_constraint_characteristics
 ;
 
# Added
_maybe_constraint_characteristics:
 | constraint_characteristics
 ;
 
# Added
_maybe_constraint_name_definition:
 | constraint_name_definition
 ;

column_constraint:
 NOT NULL | unique_specification | references_specification | check_constraint_definition
 ;

# Modified
identity_column_specification:
# generated { always | by default } as identity [ ( common_sequence_generator_options ) ]
 generated _always_or_by_default AS identity _maybe_left_paren_common_sequence_generator_options_right_paren
 ;
 
# Added
_maybe_left_paren_common_sequence_generator_options_right_paren:
 | ( common_sequence_generator_options );
  
# Added
_always_or_by_default:
 ALWAYS | BY DEFAULT
 ;

generation_clause:
 generation_rule AS generation_expression
 ;

generation_rule:
 generated always
 ;

generation_expression:
 ( value_expression ) ;

default_clause:
 default default_option
 ;

default_option:
   literal
 | datetime_value_function
 | USER
 | CURRENT_USER
 | CURRENT_ROLE
 | SESSION_USER
 | SYSTEM_USER
# Not supported
# | CURRENT_CATALOG
 | CURRENT_SCHEMA
 | CURRENT_PATH
 | implicitly_typed_value_specification
 ;

# Modified
table_constraint_definition:
# [ constraint_name_definition ] table_constraint [ constraint_characteristics ]
 _maybe_constraint_name_definition table_constraint _maybe_constraint_characteristics
 ;

table_constraint:
 unique_constraint_definition | referential_constraint_definition | check_constraint_definition
 ;

# Modified
unique_constraint_definition:
# unique_specification ( unique_column_list [ , without_overlap_specification ] ) | UNIQUE ( VALUE )
 unique_specification ( unique_column_list _maybe_comma_without_overlap_specification ) | UNIQUE( VALUE )
 ;

# Added
_maybe_comma_without_overlap_specification:
 | , without_overlap_specification
 ;
 
unique_specification:
 UNIQUE | PRIMARY KEY
 ;

unique_column_list:
 column_name_list
 ;

without_overlap_specification:
 application_time_period_name without overlaps
 ;

# Modified
referential_constraint_definition:
# foreign key ( referencing_column_list [ , referencing_period_specification ] ) references_specification
 FOREIGN KEY ( referencing_column_list _maybe_comma_referencing_period_specification ) references_specification
 ;
 
# Added
_maybe_comma_referencing_period_specification:
 | , referencing_period_specification
 ;

# Modified
references_specification:
# references referenced_table_and_columns [ match match_type ] [ referential_triggered_action ]
 references referenced_table_and_columns _maybe_match_match_type _maybe_referential_triggered_action 
 ;
 
# Added
_maybe_referential_triggered_action:
 | referential_triggered_action
 ;
 
# Added
_maybe_match_match_type:
 | MATCH match_type
 ;

match_type:
 FULL | PARTIAL | SIMPLE
 ;

referencing_column_list:
 column_name_list
 ;

referencing_period_specification:
 PERIOD application_time_period_name
 ;

# Modified
referenced_table_and_columns:
# table_name [ ( referenced_column_list [ , referenced_period_specification ] ) ]
 table_name _maybe_left_paren_referenced_column_list_maybe_comma_referenced_period_specification_right_paren
 ;
 
# Added
_maybe_left_paren_referenced_column_list_maybe_comma_referenced_period_specification_right_paren:
 | ( referenced_column_list _maybe_comma_referenced_period_specification ) ;
 
# Added
_maybe_comma_referenced_period_specification:
 | , referenced_period_specification
 ;

referenced_column_list:
 column_name_list
 ;

referenced_period_specification:
 PERIOD application_time_period_name
 ;

# Modified
referential_triggered_action:
# update_rule [ delete_rule ] | delete_rule [ update_rule ]
 update_rule _maybe_delete_rule | delete_rule _maybe_update_rule
 ;
 
# Added
_maybe_delete_rule:
 | delete_rule
 ;
 
# Added
_maybe_update_rule:
 | update_rule
 ;

update_rule:
 ON UPDATE referential_action
 ;

delete_rule:
 ON DELETE referential_action
 ;

referential_action:
 CASCADE | SET NULL | SET DEFAULT | RESTRICT | NO ACTION
 ;

check_constraint_definition:
 CHECK ( search_condition ) ;

alter_table_statement:
 ALTER TABLE table_name alter_table_action
 ;

alter_table_action:
   add_column_definition
 | alter_column_definition
 | drop_column_definition
 | add_table_constraint_definition
 | alter_table_constraint_definition
 | drop_table_constraint_definition
# Not supported
# | add_table_period_definition
# Not supported
# | drop_table_period_definition
 | add_system_versioning_clause
 | drop_system_versioning_clause
 ;

# Modified
add_column_definition:
# add [ column ] column_definition
 ADD _maybe_column column_definition
 ;
 
# Added
_maybe_column:
 | COLUMN
 ;

alter_column_definition:
 ALTER _maybe_column column_name alter_column_action
 ;

alter_column_action:
 set_column_default_clause | drop_column_default_clause | set_column_not_null_clause | drop_column_not_null_clause | add_column_scope_clause | drop_column_scope_clause | alter_column_data_type_clause | alter_identity_column_specification | drop_identity_property_clause | drop_column_generation_expression_clause
 ;

set_column_default_clause:
 SET default_clause
 ;

drop_column_default_clause:
 DROP DEFAULT
 ;

set_column_not_null_clause:
 SET NOT NULL
 ;

drop_column_not_null_clause:
 DROP NOT NULL
 ;

add_column_scope_clause:
 ADD scope_clause
 ;

drop_column_scope_clause:
 DROP scope drop_behavior
 ;

alter_column_data_type_clause:
 SET DATA TYPE data_type
 ;

# Modified
alter_identity_column_specification:
# set_identity_column_generation_clause [ alter_identity_column_option... ] | alter_identity_column_option...
 set_identity_column_generation_clause _maybe_alter_identity_column_option_multi | _alter_identity_column_option_multi
 ;
 
# Added
_alter_identity_column_option_multi:
   alter_identity_column_option
 | alter_identity_column_option
 | alter_identity_column_option
 | alter_identity_column_option
 | alter_identity_column_option
 | alter_identity_column_option _alter_identity_column_option_multi
 ;
 
# Added
_maybe_alter_identity_column_option_multi:
 | | | | | |
 alter_identity_column_option _maybe_alter_identity_column_option_multi
 ;

# Modified
set_identity_column_generation_clause:
# set generated { always | by default }
 SET GENERATED _always_or_by_default
 ;

alter_identity_column_option:
 alter_sequence_generator_restart_option | set basic_sequence_generator_option
 ;

drop_identity_property_clause:
 DROP IDENTITY
 ;

drop_column_generation_expression_clause:
 DROP EXPRESSION
 ;

# Modified
drop_column_definition:
# drop [ column ] column_name drop_behavior
 DROP _maybe_column column_name drop_behavior
 ;

add_table_constraint_definition:
 ADD table_constraint_definition
 ;

alter_table_constraint_definition:
 ALTER CONSTRAINT constraint_name constraint_enforcement
 ;

drop_table_constraint_definition:
 DROP CONSTRAINT constraint_name drop_behavior
 ;

# Modified
# Not supported
add_table_period_definition:
# add table_period_definition [ add_system_time_period_column_list ]
 ADD table_period_definition _maybe_add_system_time_period_column_list
 ;
 
# Added
_maybe_add_system_time_period_column_list:
 | add_system_time_period_column_list
 ;

# Modified
add_system_time_period_column_list:
# add [ column ] column_definition_1 add [ column ] column_definition_2
 ADD _maybe_column column_definition_1 ADD _maybe_column column_definition_2
 ;

column_definition_1:
 column_definition
 ;

column_definition_2:
 column_definition
 ;

# Not supported
drop_table_period_definition:
 DROP system_or_application_time_period_specification drop_behavior
 ;

add_system_versioning_clause:
 ADD system_versioning_clause
 ;

drop_system_versioning_clause:
 DROP SYSTEM VERSIONING drop_behavior
 ;

drop_table_statement:
 DROP TABLE table_name drop_behavior
 ;

# Modified
view_definition:
# create [ recursive ] view table_name view_specification as query_expression [ with [ levels_clause ] check option ]
 CREATE _maybe_recursive VIEW table_name view_specification AS query_expression _maybe_with_maybe_levels_clause_check_option
 ;
 
# Added
_maybe_with_maybe_levels_clause_check_option:
 | WITH _maybe_levels_clause check option
 ;
 
# Added
_maybe_levels_clause:
 | levels_clause
 ;

view_specification:
 regular_view_specification | referenceable_view_specification
 ;

# Modified
regular_view_specification:
# [ ( view_column_list ) ]
 _maybe_left_paren_view_column_list_right_paren
 ;
 
# Added
_maybe_left_paren_view_column_list_right_paren:
 | ( view_column_list ) ;
 
# Modified
referenceable_view_specification:
# of path_resolved_user_defined_type_name [ subview_clause ] [ view_element_list ]
 of path_resolved_user_defined_type_name _maybe_subview_clause _maybe_view_element_list
 ;
 
_maybe_view_element_list:
 | view_element_list
 ;
 
_maybe_subview_clause:
 | subview_clause
 ;
 
subview_clause:
 UNDER table_name
 ;

# Modified
view_element_list:
# ( view_element [ { , view_element }... ] ) 
 ( view_element _maybe_comma_view_element_multi ) ;
 
# Added
_maybe_comma_view_element_multi:
 | | | | | |
 , view_element _maybe_comma_view_element_multi
 ;

view_element:
 self_referencing_column_specification | view_column_option
 ;

view_column_option:
 column_name with options scope_clause
 ;

levels_clause:
 CASCADED | LOCAL
 ;

view_column_list:
 column_name_list
 ;

drop_view_statement:
 DROP VIEW table_name drop_behavior
 ;

# Modified
domain_definition:
# create domain domain_name [ as ] predefined_type [ default_clause ] [ domain_constraint... ] [ collate_clause ]
 CREATE DOMAIN domain_name _maybe_as predefined_type _maybe_default_clause _maybe_domain_constraint_multi _maybe_collate_clause
 ;
 
# Added
_maybe_domain_constraint_multi:
 | | | | | |
 domain_constraint _maybe_domain_constraint_multi
 ;

# Modified
domain_constraint:
# [ constraint_name_definition ] check_constraint_definition [ constraint_characteristics ]
 _maybe_constraint_name_definition check_constraint_definition _maybe_constraint_characteristics
 ;

alter_domain_statement:
 ALTER DOMAIN domain_name alter_domain_action
 ;

alter_domain_action:
 set_domain_default_clause | drop_domain_default_clause | add_domain_constraint_definition | drop_domain_constraint_definition
 ;

set_domain_default_clause:
 SET default_clause
 ;

drop_domain_default_clause:
 DROP DEFAULT
 ;

add_domain_constraint_definition:
 ADD domain_constraint
 ;

drop_domain_constraint_definition:
 DROP CONSTRAINT constraint_name
 ;

drop_domain_statement:
 DROP DOMAIN domain_name drop_behavior
 ;

# Modified
character_set_definition:
# create character set character_set_name [ as ] character_set_source [ collate_clause ]
 CREATE CHARACTER SET character_set_name _maybe_as character_set_source _maybe_collate_clause
 ;

character_set_source:
 GET character_set_specification
 ;

drop_character_set_statement:
 DROP CHARACTER SET character_set_name
 ;

# Modified
collation_definition:
# create collation collation_name FOR character_set_specification from existing_collation_name [ pad_characteristic ]
 CREATE COLLATION collation_name FOR character_set_specification FROM existing_collation_name _maybe_pad_characteristic
 ;
 
# Added
_maybe_pad_characteristic:
 | pad_characteristic
 ;

existing_collation_name:
 collation_name
 ;

pad_characteristic:
   NO PAD 
 | PAD SPACE
 ;

drop_collation_statement:
 DROP COLLATION collation_name drop_behavior
 ;

transliteration_definition:
 CREATE TRANSLATION transliteration_name FOR source_character_set_specification TO target_character_set_specification FROM transliteration_source
 ;

source_character_set_specification:
 character_set_specification
 ;

target_character_set_specification:
 character_set_specification
 ;

transliteration_source:
 existing_transliteration_name | transliteration_routine
 ;

existing_transliteration_name:
 transliteration_name
 ;

transliteration_routine:
 specific_routine_designator
 ;

drop_transliteration_statement:
 DROP TRANSLATION transliteration_name
 ;

# Modified
assertion_definition:
# create assertion constraint_name check ( search_condition ) [ constraint_characteristics ]
 CREATE ASSERTION constraint_name check ( search_condition ) _maybe_constraint_characteristics
 ;

# Modified
drop_assertion_statement:
# drop assertion constraint_name [ drop_behavior ]
 DROP ASSERTION constraint_name _maybe_drop_behavior
 ;
 
# Added
_maybe_drop_behavior:
 | drop_behavior
 ;
 
# Modified
trigger_definition:
# create trigger trigger_name trigger_action_time trigger_event on table_name [ referencing transition_table_or_variable_list ] triggered_action
 CREATE TRIGGER trigger_name trigger_action_time trigger_event ON table_name _maybe_referencing_transition_table_or_variable_list triggered_action
 ;
 
# Added
_maybe_referencing_transition_table_or_variable_list:
# Not supported
# | REFERENCING transition_table_or_variable_list
 ;

trigger_action_time:
 BEFORE | AFTER | INSTEAD OF
 ;

# Modified
trigger_event:
# insert | delete | update [ of trigger_column_list ]
 INSERT | DELETE | UPDATE _maybe_of_trigger_column_list
 ;
 
# Added
_maybe_of_trigger_column_list:
 | OF trigger_column_list
 ;

trigger_column_list:
 column_name_list
 ;

# Modified
triggered_action:
# [ FOR each { row | statement } ] [ triggered_when_clause ] triggered_sql_statement
 _maybe_for_each_row_or_statement _maybe_triggered_when_clause triggered_sql_statement
 ;
 
# Added
_maybe_triggered_when_clause:
 | triggered_when_clause
 ;
 
# Added
_maybe_for_each_row_or_statement:
 | FOR each _row_or_statement
 ;
 
# Added
_row_or_statement:
 ROW | STATEMENT
 ;

triggered_when_clause:
 WHEN ( search_condition ) ;

# Modified
triggered_sql_statement:
# sql_procedure_statement | begin atomic { sql_procedure_statement semicolon }... end
 sql_procedure_statement | BEGIN ATOMIC _sql_procedure_statement_semicolon_multi END
 ;
 
# Added
_sql_procedure_statement_semicolon_multi:
   sql_procedure_statement semicolon
 | sql_procedure_statement semicolon
 | sql_procedure_statement semicolon
 | sql_procedure_statement semicolon
 | sql_procedure_statement semicolon
 | sql_procedure_statement semicolon _sql_procedure_statement_semicolon_multi
 ;

# Modified
# Not supported
transition_table_or_variable_list:
# transition_table_or_variable...
 _transition_table_or_variable_multi
 ;
 
# Added
# Not supported
_transition_table_or_variable_multi:
   transition_table_or_variable
 | transition_table_or_variable
 | transition_table_or_variable
 | transition_table_or_variable
 | transition_table_or_variable
 | transition_table_or_variable _transition_table_or_variable_multi
 ;

# Modified
# Not supported
transition_table_or_variable:
# old [ row ] [ as ] old_transition_variable_name | new [ row ] [ as ] new_transition_variable_name | old table [ as ] old_transition_table_name | new table [ as ] new_transition_table_name
   OLD _maybe_row _maybe_as old_transition_variable_name 
 | NEW _maybe_row _maybe_as new_transition_variable_name 
 | OLD TABLE _maybe_as old_transition_table_name 
 | NEW TABLE _maybe_as new_transition_table_name
 ;
 
# Added
_maybe_row:
 | ROW
 ;

old_transition_table_name:
 transition_table_name
 ;

new_transition_table_name:
 transition_table_name
 ;

transition_table_name:
 identifier
 ;

old_transition_variable_name:
 correlation_name
 ;

new_transition_variable_name:
 correlation_name
 ;

drop_trigger_statement:
 DROP TRIGGER trigger_name
 ;

user_defined_type_definition:
 CREATE TYPE user_defined_type_body
 ;

# Modified
user_defined_type_body:
# schema_resolved_user_defined_type_name [ subtype_clause ] [ as representation ] [ user_defined_type_option_list ] [ method_specification_list ]
 schema_resolved_user_defined_type_name _maybe_subtype_clause _maybe_as_representation _maybe_user_defined_type_option_list _maybe_method_specification_list
 ;

# Added
_maybe_method_specification_list:
 | method_specification_list
 ;
 
# Added
_maybe_user_defined_type_option_list:
 | user_defined_type_option_list
 ;
 
# Added 
_maybe_subtype_clause:
 | subtype_clause
 ;
 
# Added
_maybe_as_representation:
 | AS representation
 ;

# Modified
user_defined_type_option_list:
# user_defined_type_option [ user_defined_type_option... ]
 user_defined_type_option _maybe_user_defined_type_option_multi
 ;
 
# Added
_maybe_user_defined_type_option_multi:
 | | | | | |
# Not supported
# user_defined_type_option _maybe_user_defined_type_option_multi
 ;

user_defined_type_option:
   instantiable_clause
 | finality
 | reference_type_specification
 | cast_to_ref
 | cast_to_type
 | cast_to_distinct
 | cast_to_source
 ;

subtype_clause:
 UNDER supertype_name
 ;

supertype_name:
 path_resolved_user_defined_type_name
 ;

representation:
   predefined_type
# Not supported
# | collection_type
 | member_list
 ;

# Modified
member_list:
# ( member [ { , member }... ] ) ( member _maybe_comma_member_multi ) ;
 
# Added
_maybe_comma_member_multi:
 | | | | | |
 , member _maybe_comma_member_multi
 ;

member:
 attribute_definition
 ;

instantiable_clause:
   INSTANTIABLE 
 | NOT INSTANTIABLE
 ;

finality:
   FINAL 
 | NOT FINAL
 ;

reference_type_specification:
 user_defined_representation | derived_representation | system_generated_representation
 ;

user_defined_representation:
 REF USING predefined_type
 ;

derived_representation:
 REF FROM list_of_attributes
 ;

system_generated_representation:
 REF IS SYSTEM GENERATED
 ;

cast_to_ref:
 CAST( source AS REF ) WITH cast_to_ref_identifier
 ;

cast_to_ref_identifier:
 identifier
 ;

cast_to_type:
 CAST( REF AS source ) WITH cast_to_type_identifier
 ;

cast_to_type_identifier:
 identifier
 ;

# Modified
list_of_attributes:
# ( attribute_name [ { , attribute_name }... ] ) 
 ( attribute_name _maybe_comma_attribute_name_multi ) 
 ;
 
# Added
_maybe_comma_attribute_name_multi:
 | | | | | |
 , attribute_name _maybe_comma_attribute_name_multi
 ;

cast_to_distinct:
 CAST( SOURCE AS DISTINCT ) WITH cast_to_distinct_identifier
 ;

cast_to_distinct_identifier:
 identifier
 ;

cast_to_source:
 CAST( DISTINCT AS SOURCE ) WITH cast_to_source_identifier
 ;

cast_to_source_identifier:
 identifier
 ;

# Modified
method_specification_list:
# method_specification [ { , method_specification }... ]
 method_specification _maybe_comma_method_specification_multi
 ;
 
# Added
_maybe_comma_method_specification_multi:
 | | | | | |
 , method_specification _maybe_comma_method_specification_multi
 ;

method_specification:
 original_method_specification | overriding_method_specification
 ;

# Modified
original_method_specification:
# partial_method_specification [ self AS result ] [ self AS locator ] [ method_characteristics ]
 partial_method_specification _maybe_self_as_result _maybe_self_as_locator _maybe_method_characteristics
 ;
 
# Added
_maybe_method_characteristics:
 | method_characteristics
 ;
 
# Added
_maybe_self_as_locator:
 | SELF AS LOCATOR
 ;
 
# Added
_maybe_self_as_result:
 | SELF AS RESULT
 ;

overriding_method_specification:
 overriding partial_method_specification
 ;

# Modified
partial_method_specification:
# [ instance | static | constructor ] method method_name sql_parameter_declaration_list returns_clause [ specific specific_method_name ]
 _maybe_instance_or_static_or_constructor method method_name sql_parameter_declaration_list returns_clause _maybe_specific_specific_method_name
 ;
 
# Added
_maybe_specific_specific_method_name:
 | SPECIFIC specific_method_name
 ;

# Modified
specific_method_name:
# [ schema_name period ] qualified_identifier
 _maybe_schema_name_period qualified_identifier
 ;

# Modified
method_characteristics:
# method_characteristic...
 _method_characteristic_multi
 ;
 
# Added
_method_characteristic_multi:
   method_characteristic
 | method_characteristic
 | method_characteristic
 | method_characteristic
 | method_characteristic
 | method_characteristic _method_characteristic_multi
 ;

method_characteristic:
 language_clause | parameter_style_clause | deterministic_characteristic | sql_data_access_indication | null_call_clause
 ;

# Modified
attribute_definition:
# attribute_name data_type [ attribute_default ] [ collate_clause ]
 attribute_name data_type _maybe_attribute_default _maybe_collate_clause
 ;
 
# Added
_maybe_attribute_default:
 | attribute_default
 ;

attribute_default:
 default_clause
 ;

alter_type_statement:
 ALTER TYPE schema_resolved_user_defined_type_name alter_type_action
 ;

alter_type_action:
 add_attribute_definition | drop_attribute_definition | add_original_method_specification | add_overriding_method_specification | drop_method_specification
 ;

add_attribute_definition:
 ADD ATTRIBUTE attribute_definition
 ;

drop_attribute_definition:
 DROP ATTRIBUTE attribute_name restrict
 ;

add_original_method_specification:
 ADD original_method_specification
 ;

add_overriding_method_specification:
 ADD overriding_method_specification
 ;

drop_method_specification:
 DROP specific_method_specification_designator restrict
 ;

# Modified
specific_method_specification_designator:
# [ instance | static | constructor ] method method_name data_type_list
 _maybe_instance_or_static_or_constructor method method_name data_type_list
 ;

drop_data_type_statement:
 DROP TYPE schema_resolved_user_defined_type_name drop_behavior
 ;

sql_invoked_routine:
 schema_routine
 ;

schema_routine:
 schema_procedure | schema_function
 ;

schema_procedure:
 CREATE sql_invoked_procedure
 ;

schema_function:
 CREATE sql_invoked_function
 ;

sql_invoked_procedure:
 PROCEDURE schema_qualified_routine_name sql_parameter_declaration_list routine_characteristics routine_body
 ;

# Modified
sql_invoked_function:
# { function_specification | method_specification_designator } routine_body
 _function_specification_or_method_specificaton_designator routine_body
 ;
 
# Added
_function_specification_or_method_specificaton_designator:
 function_specification | method_specification_designator
 ;

# Modified
sql_parameter_declaration_list:
# ( [ sql_parameter_declaration [ { , sql_parameter_declaration }... ] ] ) 
 ( _maybe_sql_parameter_declaration_maybe_comma_sql_parameter_declaration_multi ) 
 ;
 
# Added
_maybe_sql_parameter_declaration_maybe_comma_sql_parameter_declaration_multi:
 sql_parameter_declaration _maybe_comma_sql_parameter_declaration_multi 
 ;
 
# Added
_maybe_comma_sql_parameter_declaration_multi:
 | | | | | |
 , sql_parameter_declaration _maybe_comma_sql_parameter_declaration_multi
 ;

# Modified
sql_parameter_declaration:
# [ parameter_mode ] [ sql_parameter_name ] parameter_type [ result ] [ default parameter_default ]
 _maybe_parameter_mode _maybe_sql_parameter_name parameter_type _maybe_result _maybe_default_parameter_default
 ;
 
# Added
_maybe_default_parameter_default:
 | DEFAULT parameter_default
 ;
 
# Added
_maybe_result:
 | RESULT
 ;
 
# Added
_maybe_sql_parameter_name:
 | sql_parameter_name
 ;
 
# Added
_maybe_parameter_mode:
 | parameter_mode
 ;

parameter_default:
 value_expression | contextually_typed_value_specification
 ;

parameter_mode:
 IN | OUT | INOUT
 ;

# Modified
parameter_type:
# data_type [ locator_indication ]
 data_type _maybe_locator_indication
 ;
 
# Added
_maybe_locator_indication:
 | locator_indication
 ;

locator_indication:
 AS locator
 ;

# Modified
function_specification:
# function schema_qualified_routine_name sql_parameter_declaration_list returns_clause routine_characteristics [ dispatch_clause ]
 function schema_qualified_routine_name sql_parameter_declaration_list returns_clause routine_characteristics _maybe_dispatch_clause
 ;
 
# Added
_maybe_dispatch_clause:
 | dispatch_clause
 ;

# Modified
method_specification_designator:
# specific method specific_method_name | [ instance | static | constructor ] method method_name sql_parameter_declaration_list [ returns_clause ] FOR schema_resolved_user_defined_type_name
 specific method specific_method_name | _maybe_instance_or_static_or_constructor method method_name sql_parameter_declaration_list _maybe_returns_clause FOR schema_resolved_user_defined_type_name
 ;
 
# Added
_maybe_returns_clause:
 | returns_clause
 ;

# Modified
routine_characteristics:
# [ routine_characteristic... ]
 _maybe_routine_characteristic_multi
 ;
 
# Added
_maybe_routine_characteristic_multi:
 | | | | | |
 routine_characteristic _maybe_routine_characteristic_multi
 ;

routine_characteristic:
 language_clause | parameter_style_clause | specific specific_name | deterministic_characteristic | sql_data_access_indication | null_call_clause | returned_result_sets_characteristic | savepoint_level_indication
 ;

savepoint_level_indication:
   NEW SAVEPOINT LEVEL 
 | OLD SAVEPOINT LEVEL
 ;

returned_result_sets_characteristic:
 DYNAMIC RESULT SETS maximum_returned_result_sets
 ;

parameter_style_clause:
 PARAMETER STYLE parameter_style
 ;

dispatch_clause:
 STATIC DISPATCH
 ;

returns_clause:
 RETURNS returns_type
 ;

# Modified
returns_type:
# returns_data_type [ result_cast ] | returns_table_type
 returns_data_type _maybe_result_cast | returns_table_type
 ;
 
# Added
_maybe_result_cast:
 | result_cast
 ;

returns_table_type:
 TABLE table_function_column_list
 ;

# Modified 
table_function_column_list:
# ( table_function_column_list_element [ { , table_function_column_list_element }... ] ) 
 ( table_function_column_list_element _maybe_comma_table_function_column_list_element_multi ) ;
 
# Added
_maybe_comma_table_function_column_list_element_multi:
 | | | | | |
 , table_function_column_list_element _maybe_comma_table_function_column_list_element_multi
 ;

table_function_column_list_element:
 column_name data_type
 ;

result_cast:
 CAST FROM result_cast_from_type
 ;

# Modified
result_cast_from_type:
# data_type [ locator_indication ]
 data_type _maybe_locator_indication
 ;

# Modified
returns_data_type:
# data_type [ locator_indication ]
 data_type _maybe_locator_indication
 ;

routine_body:
 sql_routine_spec | external_body_reference
 ;

# Modified
sql_routine_spec:
# [ rights_clause ] sql_routine_body
 _maybe_rights_clause sql_routine_body
 ;
 
# Added
_maybe_rights_clause:
 | rights_clause
 ;

rights_clause:
 SQL SECURITY INVOKER | SQL SECURITY DEFINER
 ;

sql_routine_body:
 sql_procedure_statement
 ;

# Modified 
external_body_reference:
# external [ name external_routine_name ] [ parameter_style_clause ] [ transform_group_specification ] [ external_security_clause ]
 EXTERNAL _maybe_name_external_routine_name _maybe_parameter_style_clause _maybe_transform_group_specification _maybe_external_security_clause
 ;
 
# Added
_maybe_external_security_clause:
 | external_security_clause
 ;
 
# Added
_maybe_transform_group_specification:
 | transform_group_specification
 ;
 
# Added
_maybe_parameter_style_clause:
 | parameter_style_clause
 ;
 
# Added
_maybe_name_external_routine_name:
 | NAME external_routine_name
;
 

external_security_clause:
   EXTERNAL SECURITY DEFINER 
 | EXTERNAL SECURITY INVOKER 
 | EXTERNAL SECURITY IMPLEMENTATION DEFINED
 ;

parameter_style:
   SQL 
 | GENERAL
 ;

deterministic_characteristic:
   DETERMINISTIC 
 | NOT DETERMINISTIC
 ;

sql_data_access_indication:
   NO SQL 
 | CONTAINS SQL 
 | READS SQL DATA 
 | MODIFIES SQL DATA
 ;

null_call_clause:
   RETURNS NULL ON NULL INPUT 
 | CALLED ON NULL INPUT
 ;

maximum_returned_result_sets:
 unsigned_integer
 ;

# Modified
transform_group_specification:
# transform group { single_group_specification | multiple_group_specification }
 TRANSFORM GROUP _single_group_specification_or_multiple_group_specification
 ;
 
# Added
_single_group_specification_or_multiple_group_specification:
 single_group_specification | multiple_group_specification
 ;

single_group_specification:
 group_name
 ;

# Modified
multiple_group_specification:
# group_specification [ { , group_specification }... ]
 group_specification _maybe_comma_group_specification_multi
 ;
 
# Added
_maybe_comma_group_specification_multi:
 | | | | | |
 , group_specification _maybe_comma_group_specification_multi
 ;

group_specification:
 group_name FOR type path_resolved_user_defined_type_name
 ;

alter_routine_statement:
 ALTER specific_routine_designator alter_routine_characteristics alter_routine_behavior
 ;

# Modified
alter_routine_characteristics:
# alter_routine_characteristic...
 _alter_routine_characteristic_multi
 ;
 
# Added
_alter_routine_characteristic_multi:
   alter_routine_characteristic
 | alter_routine_characteristic
 | alter_routine_characteristic
 | alter_routine_characteristic
 | alter_routine_characteristic
 | alter_routine_characteristic _alter_routine_characteristic_multi
 ;

alter_routine_characteristic:
 language_clause | parameter_style_clause | sql_data_access_indication | null_call_clause | returned_result_sets_characteristic | name external_routine_name
 ;

alter_routine_behavior:
 RESTRICT
 ;

drop_routine_statement:
 DROP specific_routine_designator drop_behavior
 ;

# Modified
user_defined_cast_definition:
# create cast ( source_data_type as target_data_type ) with cast_function [ as assignment ]
 CREATE CAST( source_data_type AS target_data_type ) WITH cast_function _maybe_as_assignment
 ;
 
# Added
_maybe_as_assignment:
 | AS ASSIGNMENT
 ;

cast_function:
 specific_routine_designator
 ;

source_data_type:
 data_type
 ;

target_data_type:
 data_type
 ;

drop_user_defined_cast_statement:
 DROP CAST( source_data_type AS target_data_type ) drop_behavior
 ;

user_defined_ordering_definition:
 CREATE ORDERING FOR schema_resolved_user_defined_type_name ordering_form
 ;

ordering_form:
 equals_ordering_form | full_ordering_form
 ;

equals_ordering_form:
 EQUALS ONLY BY ordering_category
 ;

full_ordering_form:
 ORDER FULL BY ordering_category
 ;

ordering_category:
 relative_category | map_category | state_category
 ;

relative_category:
 RELATIVE WITH relative_function_specification
 ;

map_category:
 MAP WITH map_function_specification
 ;

# Modified
state_category:
# state [ specific_name ]
 STATE _maybe_specific_name
 ;
 
# Added
_maybe_specific_name:
 | specific_name
 ;

relative_function_specification:
 specific_routine_designator
 ;

map_function_specification:
 specific_routine_designator
 ;

drop_user_defined_ordering_statement:
 DROP ORDERING FOR schema_resolved_user_defined_type_name drop_behavior
 ;

# Modified
transform_definition:
# create { transform | transforms } FOR schema_resolved_user_defined_type_name transform_group...
 CREATE _transform_or_transforms FOR schema_resolved_user_defined_type_name _transform_group_multi
 ;
 
# Added
_transform_group_multi:
   transform_group
 | transform_group
 | transform_group
 | transform_group
 | transform_group
 | transform_group _transform_group_multi
 ;
 
# Added
_transform_or_transforms:
   TRANSFORM 
 | TRANSFORMS
 ;

transform_group:
 group_name ( transform_element_list ) ;

group_name:
 identifier
 ;

# Modified
transform_element_list:
# transform_element [ , transform_element ]
 transform_element _maybe_comma_transform_element
 ;
 
# Added
_maybe_comma_transform_element:
 | , transform_element
 ;

transform_element:
 to_sql | from_sql
 ;

to_sql:
 TO SQL WITH to_sql_function
 ;

from_sql:
 FROM SQL WITH from_sql_function
 ;

to_sql_function:
 specific_routine_designator
 ;

from_sql_function:
 specific_routine_designator
 ;

# Modified
alter_transform_statement:
# alter { transform | transforms } FOR schema_resolved_user_defined_type_name alter_group...
 ALTER _transform_or_transforms FOR schema_resolved_user_defined_type_name _alter_group_multi
 ;
 
# Added
_alter_group_multi:
   alter_group
 | alter_group
 | alter_group
 | alter_group
 | alter_group
 | alter_group _alter_group_multi
 ;

alter_group:
 group_name ( alter_transform_action_list ) ;

# Modified
alter_transform_action_list:
# alter_transform_action [ { , alter_transform_action }... ]
 alter_transform_action _maybe_comma_alter_transform_action_multi
 ;
 
# Added
_maybe_comma_alter_transform_action_multi:
 | | | | | |
 , alter_transform_action _maybe_comma_alter_transform_action_multi
 ;

alter_transform_action:
 add_transform_element_list | drop_transform_element_list
 ;

add_transform_element_list:
 ADD ( transform_element_list ) ;

# Modified
drop_transform_element_list:
# drop ( transform_kind [ , transform_kind ] drop_behavior ) 
 DROP ( transform_kind _maybe_comma_transform_kind drop_behavior ) ;
 
# Added
_maybe_comma_transform_kind:
 | , transform_kind
 ;

transform_kind:
 TO SQL | FROM SQL
 ;

# Modified 
drop_transform_statement:
# drop { transform | transforms } transforms_to_be_dropped FOR schema_resolved_user_defined_type_name drop_behavior
 DROP _transform_or_transforms transforms_to_be_dropped FOR schema_resolved_user_defined_type_name drop_behavior
 ;

transforms_to_be_dropped:
 ALL | transform_group_element
 ;

transform_group_element:
 group_name
 ;

# Modified
sequence_generator_definition:
# create sequence sequence_generator_name [ sequence_generator_options ]
 CREATE SEQUENCE sequence_generator_name _maybe_sequence_generator_options
 ;
 
# Added
_maybe_sequence_generator_options:
 | sequence_generator_options
 ;

# Modified
sequence_generator_options:
# sequence_generator_option...
 _sequence_generator_option_multi
 ;
 
# Added
_sequence_generator_option_multi:
   sequence_generator_option
 | sequence_generator_option
 | sequence_generator_option
 | sequence_generator_option
 | sequence_generator_option
 | sequence_generator_option _sequence_generator_option_multi
 ;

sequence_generator_option:
 sequence_generator_data_type_option | common_sequence_generator_options
 ;

# Modified
common_sequence_generator_options:
# common_sequence_generator_option...
 _common_sequence_generator_option_multi
 ;
 
# Added
_common_sequence_generator_option_multi:
   common_sequence_generator_option
 | common_sequence_generator_option
 | common_sequence_generator_option
 | common_sequence_generator_option
 | common_sequence_generator_option
 | common_sequence_generator_option
 | common_sequence_generator_option _common_sequence_generator_option_multi
 ;

common_sequence_generator_option:
 sequence_generator_start_with_option | basic_sequence_generator_option
 ;

basic_sequence_generator_option:
 sequence_generator_increment_by_option | sequence_generator_maxvalue_option | sequence_generator_minvalue_option | sequence_generator_cycle_option
 ;

sequence_generator_data_type_option:
 AS data_type
 ;

sequence_generator_start_with_option:
 START WITH sequence_generator_start_value
 ;

sequence_generator_start_value:
 signed_numeric_literal
 ;

sequence_generator_increment_by_option:
 INCREMENT BY sequence_generator_increment
 ;

sequence_generator_increment:
 signed_numeric_literal
 ;

sequence_generator_maxvalue_option:
   MAXVALUE sequence_generator_max_value 
 | NO MAXVALUE
 ;

sequence_generator_max_value:
 signed_numeric_literal
 ;

sequence_generator_minvalue_option:
   MINVALUE sequence_generator_min_value 
 | NO MINVALUE
 ;

sequence_generator_min_value:
 signed_numeric_literal
 ;

sequence_generator_cycle_option:
   CYCLE 
 | NO CYCLE
 ;

alter_sequence_generator_statement:
 ALTER SEQUENCE sequence_generator_name alter_sequence_generator_options
 ;

# Modified
alter_sequence_generator_options:
# alter_sequence_generator_option...
 _alter_sequence_generator_option_multi
 ;
 
# Added
_alter_sequence_generator_option_multi:
   alter_sequence_generator_option
 | alter_sequence_generator_option
 | alter_sequence_generator_option
 | alter_sequence_generator_option
 | alter_sequence_generator_option
 | alter_sequence_generator_option _alter_sequence_generator_option_multi
 ;

alter_sequence_generator_option:
 alter_sequence_generator_restart_option | basic_sequence_generator_option
 ;

# Modified
alter_sequence_generator_restart_option:
# restart [ with sequence_generator_restart_value ]
 RESTART _maybe_with_sequence_generator_restart_value
 ;
 
# Added
_maybe_with_sequence_generator_restart_value:
 | WITH sequence_generator_restart_value
 ;

sequence_generator_restart_value:
 signed_numeric_literal
 ;

drop_sequence_generator_statement:
 DROP SEQUENCE sequence_generator_name drop_behavior
 ;

grant_statement:
 grant_privilege_statement | grant_role_statement
 ;

# Modified
grant_privilege_statement:
# grant privileges TO grantee [ { , grantee }... ] [ with hierarchy option ] [ with grant option ] [ granted by grantor ]
 GRANT privileges TO grantee _maybe_comma_grantee_multi _maybe_with_hierarchy_option _maybe_with_grant_option _maybe_granted_by_grantor
 ;
 
# Added
_maybe_granted_by_grantor:
 | GRANTED BY grantor
 ;
 
# Added
_maybe_with_grant_option:
 | WITH GRANT OPTION
 ;
 
# Added
_maybe_with_hierarchy_option:
 | WITH HIERARCHY OPTION
 ;
 
# Added
_maybe_comma_grantee_multi:
 | | | | | |
 , grantee _maybe_comma_grantee_multi
 ;

privileges:
 object_privileges on object_name
 ;

# Modified
object_name:
# [ table ] table_name | domain domain_name | collation collation_name | character set character_set_name | translation transliteration_name | type schema_resolved_user_defined_type_name | sequence sequence_generator_name | specific_routine_designator
 _maybe_table table_name | domain domain_name | collation collation_name | character set character_set_name | translation transliteration_name | type schema_resolved_user_defined_type_name | sequence sequence_generator_name | specific_routine_designator
 ;
 
# Added
_maybe_table:
 | TABLE
 ;

# Modified
object_privileges:
# all privileges | action [ { , action }... ]
 ALL PRIVILEGES | action _maybe_comma_action_multi
 ;
 
# Added
_maybe_comma_action_multi:
 | | | | | |
 , action _maybe_comma_action_multi
 ;

# Modified
action:
# select | select ( privilege_column_list ) | select ( privilege_method_list ) | delete | insert [ ( privilege_column_list ) ] | update [ ( privilege_column_list ) ] | references [ ( privilege_column_list ) ] | usage | trigger | under | execute
   SELECT 
 | SELECT ( privilege_column_list ) 
 | SELECT ( privilege_method_list ) 
 | DELETE 
 | INSERT _maybe_left_paren_privilege_column_list_right_paren 
 | UPDATE _maybe_left_paren_privilege_column_list_right_paren 
 | REFERENCES _maybe_left_paren_privilege_column_list_right_paren 
 | USAGE 
 | TRIGGER 
 | UNDER 
 | EXECUTE
 ;
 
# Added
_maybe_left_paren_privilege_column_list_right_paren:
 | ( privilege_column_list ) ;

# Modified
privilege_method_list:
# specific_routine_designator [ { , specific_routine_designator }... ]
 specific_routine_designator _maybe_comma_specific_routine_designator_multi
 ;
 
# Added
_maybe_comma_specific_routine_designator_multi:
 | | | | | |
 , specific_routine_designator _maybe_comma_specific_routine_designator_multi
 ;

privilege_column_list:
 column_name_list
 ;

grantee:
   PUBLIC 
 | authorization_identifier
 ;

grantor:
   CURRENT_USER 
 | CURRENT_ROLE
 ;

# Modified
role_definition:
# create role role_name [ with admin grantor ]
 CREATE ROLE role_name _maybe_with_admin_grantor
 ;
 
# Added
_maybe_with_admin_grantor:
 | WITH ADMIN grantor
 ;

# Modified
grant_role_statement:
# grant role_granted [ { , role_granted }... ] to grantee [ { , grantee }... ] [ with admin option ] [ granted by grantor ]
 GRANT role_granted _maybe_comma_role_granted_multi TO grantee _maybe_comma_grentee_multi _maybe_with_admin_option _maybe_granted_by_grantor
 ;
 
# Added
_maybe_with_admin_option:
 | WITH ADMIN OPTION
 ;
 
# Added
_maybe_comma_grentee_multi:
 | | | | | |
 , grantee _maybe_comma_grentee_multi
 ;
 
# Added
_maybe_comma_role_granted_multi:
 | | | | | |
 , role_granted _maybe_comma_role_granted_multi
 ;

role_granted:
 role_name
 ;

drop_role_statement:
 DROP ROLE role_name
 ;

revoke_statement:
 revoke_privilege_statement | revoke_role_statement
 ;

# Modified
revoke_privilege_statement:
# revoke [ revoke_option_extension ] privileges from grantee [ { , grantee }... ] [ granted by grantor ] drop_behavior
 REVOKE _maybe_revoke_option_extension privileges FROM grantee _maybe_comma_grantee_multi _maybe_granted_by_grantor drop_behavior
 ;
 
# Added
_maybe_revoke_option_extension:
 | revoke_option_extension
 ;

revoke_option_extension:
   GRANT OPTION FOR 
 | HIERARCHY OPTION FOR
 ;

# Modified
revoke_role_statement:
# revoke [ admin option FOR ] role_revoked [ { , role_revoked }... ] from grantee [ { , grantee }... ] [ granted by grantor ] drop_behavior
 REVOKE _maybe_admin_option_for role_revoked _maybe_comma_role_revoked_multi FROM grantee _maybe_comma_grantee_multi _maybe_granted_by_grantor drop_behavior
 ;
 
# Added
_maybe_comma_role_revoked_multi:
 | | | | | |
 , role_revoked _maybe_comma_role_revoked_multi
 ;
 
# Added
_maybe_admin_option_for:
 | ADMIN OPTION FOR
 ;

role_revoked:
 role_name
 ;

# Modified
sql_client_module_definition:
# module_name_clause language_clause module_authorization_clause [ module_path_specification ] [ module_transform_group_specification ] [ module_collations ] [ temporary_table_declaration... ] module_contents...
 module_name_clause language_clause module_authorization_clause _maybe_module_path_specification _maybe_module_transform_group_specification _maybe_module_collations _maybe_temporary_table_declaration_multi _module_contents_multi
 ;
 
# Added
_module_contents_multi:
   module_contents
 | module_contents
 | module_contents
 | module_contents
 | module_contents
 | module_contents _module_contents_multi
 ;
 
# Added
_maybe_temporary_table_declaration_multi:
 | | | | | |
 temporary_table_declaration _maybe_temporary_table_declaration_multi
 ;
 
# Added
_maybe_module_collations:
 | module_collations
 ;
 
# Added
_maybe_module_transform_group_specification:
 | module_transform_group_specification
 ;
 
# Added
_maybe_module_path_specification:
 | module_path_specification
 ;

# Modified
module_authorization_clause:
# schema schema_name | authorization module_authorization_identifier [ FOR static { only | and dynamic } ] | schema schema_name authorization module_authorization_identifier [ FOR STATIC { only | and dynamic } ]
 schema schema_name | authorization module_authorization_identifier _maybe_for_static_only_or_and_dynamic | schema schema_name authorization module_authorization_identifier _maybe_for_static_only_or_and_dynamic
 ;
 
# Added
_maybe_for_static_only_or_and_dynamic:
 | FOR STATIC _only_or_and_dynamic
 ;
 
# Added
_only_or_and_dynamic:
 ONLY | AND DYNAMIC
 ;

module_authorization_identifier:
 authorization_identifier
 ;

module_path_specification:
 path_specification
 ;

module_transform_group_specification:
 transform_group_specification
 ;

# Modified
module_collations:
# module_collation_specification...
 _module_collation_specification_multi
 ;
 
# Added
_module_collation_specification_multi:
   module_collation_specification
 | module_collation_specification
 | module_collation_specification
 | module_collation_specification
 | module_collation_specification
 | module_collation_specification _module_collation_specification_multi
 ;

# Modified
module_collation_specification:
# collation collation_name [ FOR character_set_specification_list ]
 COLLATION collation_name _maybe_for_character_set_specification_list
 ;
 
# Added
_maybe_for_character_set_specification_list:
 | FOR character_set_specification_list
 ;

# Modified
character_set_specification_list:
# character_set_specification [ { , character_set_specification }... ]
 character_set_specification _maybe_comma_character_set_specification_multi
 ;
 
# Added
_maybe_comma_character_set_specification_multi:
 | | | | | |
 , character_set_specification _maybe_comma_character_set_specification_multi
 ;

module_contents:
 declare_cursor | dynamic_declare_cursor | externally_invoked_procedure
 ;

# Modified
# Not supported
module_name_clause:
# module [ sql_client_module_name ] [ module_character_set_specification ]
 MODULE _maybe_sql_client_module_name _maybe_module_character_set_specification
 ;
 
# Added
_maybe_module_character_set_specification:
 | module_character_set_specification
 ;
 
# Added
_maybe_sql_client_module_name:
 | sql_client_module_name
 ;

module_character_set_specification:
 NAMES ARE character_set_specification
 ;

externally_invoked_procedure:
 PROCEDURE procedure_name host_parameter_declaration_list semicolon sql_procedure_statement semicolon
 ;

# Modified
host_parameter_declaration_list:
# ( host_parameter_declaration [ { , host_parameter_declaration }... ] ) 
 ( host_parameter_declaration _maybe_comma_host_parameter_declaration_multi ) ;
 
# Added
_maybe_comma_host_parameter_declaration_multi:
 | | | | | |
 , host_parameter_declaration _maybe_comma_host_parameter_declaration_multi
 ;

host_parameter_declaration:
 host_parameter_name host_parameter_data_type | status_parameter
 ;

# Modified
host_parameter_data_type:
# data_type [ locator_indication ]
 data_type _maybe_locator_indication
 ;

status_parameter:
 SQLSTATE
 ;

sql_procedure_statement:
 sql_executable_statement
 ;

sql_executable_statement:
 sql_schema_statement | sql_data_statement | sql_control_statement | sql_transaction_statement | sql_connection_statement | sql_session_statement | sql_diagnostics_statement | sql_dynamic_statement
 ;

sql_schema_statement:
 sql_schema_definition_statement | sql_schema_manipulation_statement
 ;

sql_schema_definition_statement:
 schema_definition | table_definition | view_definition | sql_invoked_routine | grant_statement | role_definition | domain_definition | character_set_definition | collation_definition | transliteration_definition | assertion_definition | trigger_definition | user_defined_type_definition | user_defined_cast_definition | user_defined_ordering_definition | transform_definition | sequence_generator_definition
 ;

sql_schema_manipulation_statement:
 drop_schema_statement | alter_table_statement | drop_table_statement | drop_view_statement | alter_routine_statement | drop_routine_statement | drop_user_defined_cast_statement | revoke_statement | drop_role_statement | alter_domain_statement | drop_domain_statement | drop_character_set_statement | drop_collation_statement | drop_transliteration_statement | drop_assertion_statement | drop_trigger_statement | alter_type_statement | drop_data_type_statement | drop_user_defined_ordering_statement | alter_transform_statement | drop_transform_statement | alter_sequence_generator_statement | drop_sequence_generator_statement
 ;

sql_data_statement:
 open_statement | fetch_statement | close_statement | select_statement__single ROW | free_locator_statement | hold_locator_statement | sql_data_change_statement
 ;

sql_data_change_statement:
 delete_statement__positioned | delete_statement__searched | insert_statement | update_statement__positioned | update_statement__searched | truncate_table_statement | merge_statement
 ;

sql_control_statement:
 call_statement | return_statement
 ;

sql_transaction_statement:
 start_transaction_statement | set_transaction_statement | set_constraints_mode_statement | savepoint_statement | release_savepoint_statement | commit_statement | rollback_statement
 ;

sql_connection_statement:
 connect_statement
 ;

sql_session_statement:
 set_session_user_identifier_statement | set_role_statement | set_local_time_zone_statement | set_session_characteristics_statement | set_catalog_statement | set_schema_statement | set_names_statement | set_path_statement | set_transform_group_statement | set_session_collation_statement
 ;

sql_diagnostics_statement:
 get_diagnostics_statement
 ;

sql_dynamic_statement:
 sql_descriptor_statement | prepare_statement | deallocate_prepared_statement | describe_statement | execute_statement | execute_immediate_statement | sql_dynamic_data_statement
 ;

sql_dynamic_data_statement:
 allocate_extended_dynamic_cursor_statement | allocate_received_cursor_statement | dynamic_open_statement | dynamic_fetch_statement | dynamic_close_statement | dynamic_delete_statement__positioned | dynamic_update_statement__positioned
 ;

sql_descriptor_statement:
 allocate_descriptor_statement | deallocate_descriptor_statement | set_descriptor_statement | get_descriptor_statement
 ;

declare_cursor:
 DECLARE cursor_name cursor_properties FOR cursor_specification
 ;

# Modified
cursor_properties:
# [ cursor_sensitivity ] [ cursor_scrollability ] cursor [ cursor_holdability ] [ cursor_returnability ]
 _maybe_cursor_sensitivity _maybe_cursor_scrollability cursor _maybe_cursor_holdability _maybe_cursor_returnability
 ;
 
# Added
_maybe_cursor_returnability:
 cursor_returnability
 ;
 
# Added
_maybe_cursor_holdability:
 cursor_holdability
 ;
 
# Added
_maybe_cursor_scrollability:
 | cursor_scrollability
 ;
 
# Added
_maybe_cursor_sensitivity:
 | cursor_sensitivity
 ;

cursor_sensitivity:
   SENSITIVE 
 | INSENSITIVE 
 | ASENSITIVE
 ;

cursor_scrollability:
   SCROLL 
 | NO SCROLL
 ;

cursor_holdability:
   WITH HOLD 
 | WITHOUT HOLD
 ;

cursor_returnability:
   WITH RETURN 
 | WITHOUT RETURN
 ;

# Modified
cursor_specification:
# query_expression [ updatability_clause ]
 query_expression _maybe_updatability_clause
 ;
 
# Added
_maybe_updatability_clause:
 | updatability_clause
 ;

# Modified
updatability_clause:
# FOR { read only | update [ of column_name_list ] }
 FOR _read_only_or_update_maybe_of_column_name_list
 ;
 
# Added
_read_only_or_update_maybe_of_column_name_list:
 READ ONLY | UPDATE _maybe_of_column_name_list
 ;
 
# Added
_maybe_of_column_name_list:
 | OF column_name_list
 ;

open_statement:
 OPEN cursor_name
 ;

# Modified
fetch_statement:
# fetch [ [ fetch_orientation ] from ] cursor_name into fetch_target_list
 FETCH _maybe_maybe_fetch_orientation_from cursor_name INSERT fetch_target_list
 ;
 
# Added
_maybe_maybe_fetch_orientation_from:
 | _maybe_fetch_orientation FROM
 ;
 
# Added
_maybe_fetch_orientation:
 | fetch_orientation
 ;

# Modified
fetch_orientation:
# next | prior | first | last | { absolute | relative } simple_value_specification
 NEXT | PRIOR | FIRST | LAST | _absolute_or_relative simple_value_specification
 ;
 
# Added
_absolute_or_relative:
 ABSOLUTE | RELATIVE
 ;

# Modified
fetch_target_list:
# target_specification [ { , target_specification }... ]
 target_specification _maybe_comma_target_specification_multi
 ;
 
# Added
_maybe_comma_target_specification_multi:
 | | | | | |
 , target_specification _maybe_comma_target_specification_multi
 ;

close_statement:
 CLOSE cursor_name
 ;

# Modified 
select_statement__single_row:
# select [ set_quantifier ] select_list into select_target_list table_expression
 SELECT _maybe_set_quantifier select_list INTO select_target_list table_expression
 ;

# Modified
select_target_list:
# target_specification [ { , target_specification }... ]
 target_specification _maybe_comma_target_specification_multi
 ;

# Modified 
delete_statement__positioned:
# delete from target_table [ [ as ] correlation_name ] where current of cursor_name
 DELETE FROM target_table _maybe_maybe_as_correlation_name WHERE CURRENT OF cursor_name
 ;
 
# Added
_maybe_maybe_as_correlation_name:
 | _maybe_as correlation_name
 ;

target_table:
 table_name | ONLY ( table_name ) ;

# Modified
delete_statement__searched:
# delete from target_table [ FOR portion of application_time_period_name from point_in_time_1 TO point_in_time_2 ] [ [ as ] correlation_name ] [ where search_condition ]
 DELETE FROM target_table _maybe_for_portion_of_application_time_period_name_from_point_in_time_1_to_point_in_time_2 _maybe_maybe_as_correlation_name _maybe_where_search_condition
 ;
 
# Added
_maybe_where_search_condition:
 | WHERE search_condition
 ;
 
# Added
_maybe_for_portion_of_application_time_period_name_from_point_in_time_1_to_point_in_time_2:
 | FOR portion of application_time_period_name FROM point_in_time_1 TO point_in_time_2
 ;

# Modified
truncate_table_statement:
# truncate table target_table [ identity_column_restart_option ]
 TRUNCATE TABLE target_table _maybe_identity_column_restart_option
 ;
 
# Added
_maybe_identity_column_restart_option:
 | identity_column_restart_option
 ;

identity_column_restart_option:
 CONTINUE IDENTITY | RESTART IDENTITY
 ;

insert_statement:
 INSERT INTO insertion_target insert_columns_and_source
 ;

insertion_target:
 table_name
 ;

insert_columns_and_source:
 from_subquery | from_constructor | from_default
 ;

# Modified
from_subquery:
# [ ( insert_column_list ) ] [ override_clause ] query_expression
 _maybe_left_paren_insert_column_list_right_paren _maybe_override_clause query_expression
 ;
 
# Added
_maybe_left_paren_insert_column_list_right_paren:
 | ( insert_column_list ) ;
 
# Added
_maybe_override_clause:
 | override_clause
 ;

# Modified 
from_constructor:
# [ ( insert_column_list ) ] [ override_clause ] contextually_typed_table_value_constructor
 _maybe_left_paren_insert_column_list_right_paren _maybe_override_clause contextually_typed_table_value_constructor
 ;

override_clause:
   OVERRIDING USER VALUE 
 | OVERRIDING SYSTEM VALUE
 ;

from_default:
 DEFAULT VALUES
 ;

insert_column_list:
 column_name_list
 ;

# Modified
merge_statement:
# merge into target_table [ [ as ] merge_correlation_name ] using table_reference on search_condition merge_operation_specification
 MERGE INTO target_table _maybe_maybe_as_merge_correlation_name USING table_reference ON search_condition merge_operation_specification
 ;
 
# Added
_maybe_maybe_as_merge_correlation_name:
 | _maybe_as merge_correlation_name
 ;

merge_correlation_name:
 correlation_name
 ;

# Modified 
merge_operation_specification:
# merge_when_clause...
 _merge_when_clause_multi
 ;
 
# Added
_merge_when_clause_multi:
   merge_when_clause
 | merge_when_clause
 | merge_when_clause
 | merge_when_clause
 | merge_when_clause
 | merge_when_clause _merge_when_clause_multi
 ;

merge_when_clause:
 merge_when_matched_clause | merge_when_not_matched_clause
 ;

# Modified
merge_when_matched_clause:
# when matched [ and search_condition ] then merge_update_or_delete_specification
 WHEN MATCHED _maybe_and_search_condition THEN merge_update_or_delete_specification
 ;
 
# Added
_maybe_and_search_condition:
 | AND search_condition
 ;

merge_update_or_delete_specification:
 merge_update_specification | merge_delete_specification
 ;

# Modified
merge_when_not_matched_clause:
# when not matched [ and search_condition ] then merge_insert_specification
 WHEN NOT MATCHED _maybe_and_search_condition THEN merge_insert_specification
 ;

merge_update_specification:
 UPDATE SET set_clause_list
 ;

merge_delete_specification:
 DELETE
 ;

# Modified
merge_insert_specification:
# insert [ ( insert_column_list ) ] [ override_clause ] values merge_insert_value_list
 INSERT _maybe_left_paren_insert_column_list_right_paren _maybe_override_clause VALUES merge_insert_value_list
 ;

# Modified
merge_insert_value_list:
# ( merge_insert_value_element [ { , merge_insert_value_element }... ] ) ( merge_insert_value_element _maybe_comma_merge_insert_value_element_multi ) ;
 
# Added
_maybe_comma_merge_insert_value_element_multi:
 | | | | | |
 , merge_insert_value_element _maybe_comma_merge_insert_value_element_multi
 ;

merge_insert_value_element:
 value_expression | contextually_typed_value_specification
 ;

# Modified
update_statement__positioned:
# update target_table [ [ as ] correlation_name ] set set_clause_list where current of cursor_name
 UPDATE target_table _maybe_maybe_as_correlation_name SET set_clause_list WHERE current of cursor_name
 ;

# Modified
update_statement__searched:
# update target_table [ FOR portion of application_time_period_name from point_in_time_1 to point_in_time_2 ] [ [ as ] correlation_name ] set set_clause_list [ where search_condition ]
 UPDATE target_table _maybe_for_portion_of_application_time_period_name_from_point_in_time_1_to_point_in_time_2 _maybe_maybe_as_correlation_name SET set_clause_list _maybe_where_search_condition
 ;
 
# Modified
set_clause_list:
# set_clause [ { , set_clause }... ]
 set_clause _maybe_comma_set_clause_multi
 ;
 
# Added
_maybe_comma_set_clause_multi:
 | | | | | |
 , set_clause _maybe_comma_set_clause_multi
 ;

set_clause:
 multiple_column_assignment | set_target equals_operator update_source
 ;

set_target:
 update_target | mutated_set_clause
 ;

multiple_column_assignment:
 set_target_list equals_operator assigned_row
 ;

# Modified
set_target_list:
# ( set_target [ { , set_target }... ] ) 
 ( set_target _maybe_comma_set_target_multi ) ;
 
_maybe_comma_set_target_multi:
 | | | | | |
 , set_target _maybe_comma_set_target_multi
 ;

assigned_row:
 contextually_typed_row_value_expression
 ;

update_target:
 object_column | object_column left_bracket_or_trigraph simple_value_specification right_bracket_or_trigraph
 ;

object_column:
 column_name
 ;

mutated_set_clause:
 mutated_target . method_name
 ;

mutated_target:
 object_column | mutated_set_clause
 ;

update_source:
 value_expression | contextually_typed_value_specification
 ;

# Modified
temporary_table_declaration:
# declare local temporary table table_name table_element_list [ on commit table_commit_action rows ]
 DECLARE LOCAL TEMPORARY TABLE table_name table_element_list _maybe_on_commit_table_commit_action_rows
 ;

# Modified
free_locator_statement:
# free locator locator_reference [ { , locator_reference }... ]
 free locator locator_reference _maybe_comma_locator_reference_multi
 ;

# Added
_maybe_comma_locator_reference_multi:
 | | | | | |
 , locator_reference _maybe_comma_locator_reference_multi
 ;
 
locator_reference:
 host_parameter_name | embedded_variable_name | dynamic_parameter_specification
 ;

# Modified
hold_locator_statement:
# hold locator locator_reference [ { , locator_reference }... ]
 HOLD LOCATOR locator_reference _maybe_comma_locator_reference_multi
 ;

call_statement:
 CALL routine_invocation
 ;

return_statement:
 RETURN return_value
 ;

return_value:
 value_expression | NULL
 ;

# Modified
start_transaction_statement:
# start transaction [ transaction_characteristics ]
 START TRANSACTION _maybe_transaction_characteristics
 ;
 
# Added
_maybe_transaction_characteristics:
 | transaction_characteristics
 ;

# Modified
set_transaction_statement:
# set [ local ] transaction transaction_characteristics
 SET _maybe_local TRANSACTION transaction_characteristics
 ;
 
# Added
_maybe_local:
 | LOCAL
 ;

# Modified
transaction_characteristics:
# [ transaction_mode [ { , transaction_mode }... ] ]
 _maybe_transaction_mode_maybe_comma_transaction_mode_multi
 ;
 
# Added
_maybe_transaction_mode_maybe_comma_transaction_mode_multi:
 | | | | | |
 transaction_mode _maybe_comma_transaction_mode_multi
 ;
 
transaction_mode:
 isolation_level | transaction_access_mode | diagnostics_size
 ;

transaction_access_mode:
   READ ONLY 
 | READ WRITE
 ;

isolation_level:
 ISOLATION LEVEL level_of_isolation
 ;

level_of_isolation:
   READ UNCOMMITTED 
 | READ COMMITTED 
 | REPEATABLE READ 
 | SERIALIZABLE
 ;

diagnostics_size:
 DIAGNOSTICS SIZE number_of_conditions
 ;

number_of_conditions:
 simple_value_specification
 ;

# Modified
set_constraints_mode_statement:
# set constraints constraint_name_list { deferred | immediate }
 SET CONSTRAINTS constraint_name_list _deferred_or_immediate
 ;
 
# Added
_deferred_or_immediate:
 DEFERRED | IMMEDIATE
 ;

# Modified
constraint_name_list:
# all | constraint_name [ { , constraint_name }... ]
 ALL | constraint_name _maybe_comma_constraint_name_multi
 ;
 
# Added
_maybe_comma_constraint_name_multi:
 | | | | | |
 , constraint_name _maybe_comma_constraint_name_multi
 ;

savepoint_statement:
 SAVEPOINT savepoint_specifier
 ;

savepoint_specifier:
 savepoint_name
 ;

release_savepoint_statement:
 RELEASE SAVEPOINT savepoint_specifier
 ;

# Modified
commit_statement:
# commit [ work ] [ and [ no ] chain ]
 COMMIT _maybe_work _maybe_and_maybe_no_chain
 ;
 
# Added
_maybe_work:
 | WORK
 ;
 
# Added
_maybe_and_maybe_no_chain:
 | AND _maybe_no CHAIN
 ;
 
# Added
_maybe_no:
 | NO
 ;

# Modified
rollback_statement:
# rollback [ work ] [ and [ no ] chain ] [ savepoint_clause ]
 ROLLBACK _maybe_work _maybe_and_maybe_no_chain _maybe_savepoint_clause
 ;
 
# Added
_maybe_savepoint_clause:
 | savepoint_clause
 ;

savepoint_clause:
 TO SAVEPOINT savepoint_specifier
 ;

connect_statement:
 CONNECT TO connection_target
 ;

# Modified
connection_target:
# sql_server_name [ as connection_name ] [ user connection_user_name ] | default
 sql_server_name _maybe_as_connection_name _maybe_user_connection_user_name | DEFAULT
 ;
 
# Added
_maybe_as_connection_name:
 | AS connection_name
 ;
 
# Added
_maybe_user_connection_user_name:
 | USER connection_user_name
 ;

set_connection_statement:
 SET CONNECTION connection_object
 ;

connection_object:
 DEFAULT | connection_name
 ;

disconnect_statement:
 DISCONNECT disconnect_object
 ;

disconnect_object:
 connection_object | ALL | CURRENT
 ;

set_session_characteristics_statement:
 SET SESSION CHARACTERISTICS AS session_characteristic_list
 ;

# Modified
session_characteristic_list:
# session_characteristic [ { , session_characteristic }... ]
 session_characteristic _maybe_comma_session_characteristic_multi
 ;
 
# Added
_maybe_comma_session_characteristic_multi:
 | | | | | |
 , session_characteristic _maybe_comma_session_characteristic_multi
 ;

session_characteristic:
 session_transaction_characteristics
 ;

# Modified
session_transaction_characteristics:
# transaction transaction_mode [ { , transaction_mode }... ]
 TRANSACTION transaction_mode _maybe_comma_transaction_mode_multi
 ;
 
# Added
_maybe_comma_transaction_mode_multi:
 | | | | | |
 , transaction_mode _maybe_comma_transaction_mode_multi
 ;

set_session_user_identifier_statement:
 SET SESSION AUTHORIZATION value_specification
 ;

set_role_statement:
 SET ROLE role_specification
 ;

role_specification:
 value_specification | NONE
 ;

set_local_time_zone_statement:
 SET TIME ZONE set_time_zone_value
 ;

set_time_zone_value:
 interval_value_expression | LOCAL
 ;

set_catalog_statement:
 SET catalog_name_characteristic
 ;

catalog_name_characteristic:
 CATALOG value_specification
 ;

set_schema_statement:
 SET schema_name_characteristic
 ;

schema_name_characteristic:
 SCHEMA value_specification
 ;

set_names_statement:
 SET character_set_name_characteristic
 ;

character_set_name_characteristic:
 NAMES value_specification
 ;

set_path_statement:
 SET sql_path_characteristic
 ;

sql_path_characteristic:
 PATH value_specification
 ;

set_transform_group_statement:
 SET transform_group_characteristic
 ;

transform_group_characteristic:
   DEFAULT TRANSFORM GROUP value_specification 
 | TRANSFORM GROUP FOR TYPE path_resolved_user_defined_type_name value_specification
 ;

# Modified
set_session_collation_statement:
# set collation collation_specification [ FOR character_set_specification_list ] | set no collation [ for character_set_specification_list ]
   SET COLLATION collation_specification _maybe_for_character_set_specification_list 
 | SET NO COLLATION _maybe_for_character_set_specification_list
 ;

collation_specification:
 value_specification
 ;

# Modified
allocate_descriptor_statement:
# allocate [ sql ] descriptor descriptor_name [ with max occurrences ]
 ALLOCATE _maybe_sql DESCRIPTOR descriptor_name _maybe_with_max_occurrences
 ;
 
# Added
_maybe_with_max_occurrences:
 | WITH MAX occurrences
 ;
 
# Added
_maybe_sql:
 | SQL
 ;

occurrences:
 simple_value_specification
 ;

# Modified
deallocate_descriptor_statement:
# deallocate [ sql ] descriptor descriptor_name
 DEALLOCATE _maybe_sql DESCRIPTOR descriptor_name
 ;

# Modified
get_descriptor_statement:
# get [ sql ] descriptor descriptor_name get_descriptor_information
 GET _maybe_sql DESCRIPTOR descriptor_name get_descriptor_information
 ;

# Modified
get_descriptor_information:
# get_header_information [ { , get_header_information }... ] | VALUE item_number get_item_information [ { , get_item_information }... ]
    get_header_information _maybe_comma_get_header_information_multi 
  | VALUE item_number get_item_information _maybe_comma_get_item_information_multi
 ;
 
# Added
_maybe_comma_get_header_information_multi:
 | | | | | |
 , get_header_information _maybe_comma_get_header_information_multi
 ;
 
# Added
_maybe_comma_get_item_information_multi:
 | | | | | |
 , get_item_information _maybe_comma_get_item_information_multi
 ;
 
get_header_information:
 simple_target_specification_1 equals_operator header_item_name
 ;

header_item_name:
   COUNT 
 | KEY_TYPE 
 | DYNAMIC_FUNCTION 
 | DYNAMIC_FUNCTION_CODE 
 | TOP_LEVEL_COUNT
 ;

get_item_information:
 simple_target_specification_2 equals_operator descriptor_item_name
 ;

item_number:
 simple_value_specification
 ;

simple_target_specification_1:
 simple_target_specification
 ;

simple_target_specification_2:
 simple_target_specification
 ;

descriptor_item_name:
   CARDINALITY 
 | CHARACTER_SET_CATALOG 
 | CHARACTER_SET_NAME 
 | CHARACTER_SET_SCHEMA 
 | COLLATION_CATALOG 
 | COLLATION_NAME 
 | COLLATION_SCHEMA 
 | DATA 
 | DATETIME_INTERVAL_CODE 
 | DATETIME_INTERVAL_PRECISION 
 | DEGREE 
 | INDICATOR 
 | KEY_MEMBER 
 | LENGTH 
 | LEVEL | NAME 
 | NULLABLE
 | OCTET_LENGTH 
 | PARAMETER_MODE 
 | PARAMETER_ORDINAL_POSITION 
 | PARAMETER_SPECIFIC_CATALOG 
 | PARAMETER_SPECIFIC_NAME 
 | PARAMETER_SPECIFIC_SCHEMA 
 | PRECISION 
 | RETURNED_CARDINALITY 
 | RETURNED_LENGTH 
 | RETURNED_OCTET_LENGTH 
 | SCALE 
 | SCOPE_CATALOG 
 | SCOPE_NAME 
 | SCOPE_SCHEMA 
 | TYPE 
 | UNNAMED 
 | USER_DEFINED_TYPE_CATALOG 
 | USER_DEFINED_TYPE_NAME 
 | USER_DEFINED_TYPE_SCHEMA 
 | USER_DEFINED_TYPE_CODE
 ;

# Modified
set_descriptor_statement:
# set [ sql ] descriptor descriptor_name set_descriptor_information
 SET _maybe_sql descriptor descriptor_name set_descriptor_information
 ;

# Modified
set_descriptor_information:
# set_header_information [ { , set_header_information }... ] | VALUE item_number set_item_information [ { , set_item_information }... ]
   set_header_information _maybe_comma_set_header_information_multi 
 | VALUE item_number set_item_information _maybe_comma_set_item_information_multi
 ;
 
# Added
_maybe_comma_set_item_information_multi:
 | | | | | |
 , set_item_information _maybe_comma_set_item_information_multi
 ;
 
# Added
_maybe_comma_set_header_information_multi:
 | | | | | |
 , set_header_information _maybe_comma_set_header_information_multi
 ;
 
set_header_information:
 header_item_name equals_operator simple_value_specification_1
 ;

set_item_information:
 descriptor_item_name equals_operator simple_value_specification_2
 ;

simple_value_specification_1:
 simple_value_specification
 ;

simple_value_specification_2:
 simple_value_specification
 ;

# Modified
prepare_statement:
# prepare sql_statement_name [ attributes_specification ] from sql_statement_variable
 PREPARE sql_statement_name _maybe_attributes_specification FROM sql_statement_variable
 ;
 
# Added
_maybe_attributes_specification:
 | attributes_specification
 ;

attributes_specification:
 attributes attributes_variable
 ;

attributes_variable:
 simple_value_specification
 ;

sql_statement_variable:
 simple_value_specification
 ;

preparable_statement:
 preparable_sql_data_statement | preparable_sql_schema_statement | preparable_sql_transaction_statement | preparable_sql_control_statement | preparable_sql_session_statement | preparable_implementation_defined_statement
 ;

preparable_sql_data_statement:
   delete_statement__searched 
 | dynamic_single_row_select_statement 
 | insert_statement 
 | dynamic_select_statement 
 | update_statement__searched 
 | truncate_table_statement 
 | merge_statement 
 | preparable_dynamic_delete_statement__positioned 
 | preparable_dynamic_update_statement__positioned 
 | hold_locator_statement 
 | free_locator_statement
 ;

preparable_sql_schema_statement:
 sql_schema_statement
 ;

preparable_sql_transaction_statement:
 sql_transaction_statement
 ;

preparable_sql_control_statement:
 sql_control_statement
 ;

preparable_sql_session_statement:
 sql_session_statement
 ;

dynamic_select_statement:
 cursor_specification
 ;

preparable_implementation_defined_statement:
 # see the syntax rules.
 ;

# Modified
cursor_attributes:
# cursor_attribute...
 _cursor_attribute_multi
 ;
 
# Added
_cursor_attribute_multi:
   cursor_attribute
 | cursor_attribute
 | cursor_attribute
 | cursor_attribute
 | cursor_attribute
 | cursor_attribute _cursor_attribute_multi
 ;

cursor_attribute:
 cursor_sensitivity | cursor_scrollability | cursor_holdability | cursor_returnability
 ;

deallocate_prepared_statement:
 deallocate prepare sql_statement_name
 ;

describe_statement:
 describe_input_statement | describe_output_statement
 ;

# Modified
describe_input_statement:
# describe input sql_statement_name using_descriptor [ nesting_option ]
 describe input sql_statement_name using_descriptor _maybe_nesting_option
 ;
 
# Added
_maybe_nesting_option:
 | nesting_option
 ;

# Modified
describe_output_statement:
# describe [ output ] described_object using_descriptor [ nesting_option ]
 DESCRIBE _maybe_output described_object using_descriptor _maybe_nesting_option
 ;
 
# Added
_maybe_output:
 | OUTPUT
 ;

nesting_option:
   WITH NESTING 
 | WITHOUT NESTING
 ;

# Modified
using_descriptor:
# using [ sql ] descriptor descriptor_name
 USING _maybe_sql DESCRIPTOR descriptor_name
 ;

described_object:
 sql_statement_name | cursor cursor_name structure
 ;

input_using_clause:
 using_arguments | using_input_descriptor
 ;

# Modified
using_arguments:
# using using_argument [ { , using_argument }... ]
 USING using_argument _maybe_comma_using_argument_multi
 ;
 
# Added
_maybe_comma_using_argument_multi:
 | | | | | |
 , using_argument _maybe_comma_using_argument_multi
 ;

using_argument:
 general_value_specification
 ;

using_input_descriptor:
 using_descriptor
 ;

output_using_clause:
 into_arguments | into_descriptor
 ;

# Modified
into_arguments:
# into into_argument [ { , into_argument }... ]
 INTO into_argument _maybe_comma_into_argument_multi
 ;
 
# Added
_maybe_comma_into_argument_multi:
 | | | | | |
 , into_argument _maybe_comma_into_argument_multi
 ;

into_argument:
 target_specification
 ;

# Modified
into_descriptor:
# into [ sql ] descriptor descriptor_name
 INTO _maybe_sql DESCRIPTOR descriptor_name
 ;

# Modified
execute_statement:
# execute sql_statement_name [ result_using_clause ] [ parameter_using_clause ]
 EXECUTE sql_statement_name _maybe_result_using_clause _maybe_parameter_using_clause
 ;
 
# Added
_maybe_parameter_using_clause:
 | parameter_using_clause
 ;
 
# Added
_maybe_result_using_clause:
 | result_using_clause
 ;

result_using_clause:
 output_using_clause
 ;

parameter_using_clause:
 input_using_clause
 ;

execute_immediate_statement:
 EXECUTE IMMEDIATE sql_statement_variable
 ;

dynamic_declare_cursor:
 DECLARE cursor_name cursor_properties FOR statement_name
 ;

allocate_extended_dynamic_cursor_statement:
 ALLOCATE extended_cursor_name cursor_properties FOR extended_statement_name
 ;

# Modified
allocate_received_cursor_statement:
# allocate cursor_name [ cursor ] FOR procedure specific_routine_designator
 ALLOCATE cursor_name _maybe_cursor FOR PROCEDURE specific_routine_designator
 ;
 
# Added
_maybe_cursor:
 | CURSOR
 ;

# Modified
dynamic_open_statement:
# open dynamic_cursor_name [ input_using_clause ]
 OPEN dynamic_cursor_name _maybe_input_using_clause
 ;
 
# Added
_maybe_input_using_clause:
 | input_using_clause
 ;

# Modified
dynamic_fetch_statement:
# fetch [ [ fetch_orientation ] from ] dynamic_cursor_name output_using_clause
 FETCH _maybe_maybe_fetch_orientation_from dynamic_cursor_name output_using_clause
 ;

dynamic_single_row_select_statement:
 query_specification
 ;

dynamic_close_statement:
 CLOSE dynamic_cursor_name
 ;
 
dynamic_delete_statement__positioned:
 DELETE FROM target_table WHERE CURRENT OF dynamic_cursor_name
 ;

dynamic_update_statement__positioned:
 UPDATE target_table SET set_clause_list WHERE CURRENT OF dynamic_cursor_name
 ;

# Modified
preparable_dynamic_delete_statement__positioned:
# delete [ from target_table ] where current of preparable_dynamic_cursor_name
 DELETE _maybe_from_target_table WHERE CURRENT OF preparable_dynamic_cursor_name
 ;
 
# Added
_maybe_from_target_table:
 | FROM target_table
 ;

# Modified
preparable_dynamic_cursor_name:
# [ scope_option ] cursor_name
 _maybe_scope_option cursor_name
 ;

embedded_sql_host_program:
 embedded_sql_ada_program | embedded_sql_c_program | embedded_sql_cobol_program | embedded_sql_fortran_program | embedded_sql_mumps_program | embedded_sql_pascal_program | embedded_sql_pl_i program
 ;
 
embedded_sql_pl_i_program:
 # see the syntax rules

# Modified
embedded_sql_statement:
# sql_prefix statement_or_declaration [ sql_terminator ]
 sql_prefix statement_or_declaration _maybe_sql_terminator
 ;
 
# Added
_maybe_sql_terminator:
 | sql_terminator
 ;

statement_or_declaration:
 declare_cursor | dynamic_declare_cursor | temporary_table_declaration | embedded_authorization_declaration | embedded_path_specification | embedded_transform_group_specification | embedded_collation_specification | embedded_exception_declaration | sql_procedure_statement
 ;

sql_prefix:
   EXEC SQL 
 | &SQL(
 ;

sql_terminator:
   END- EXEC 
 | { ';' } 
 | ) 
 ;

embedded_authorization_declaration:
 DECLARE embedded_authorization_clause
 ;

# Modified
embedded_authorization_clause:
# schema schema_name | authorization embedded_authorization_identifier [ FOR static { only | and dynamic } ] | schema schema_name authorization embedded_authorization_identifier [ FOR static { only | and dynamic } ]
   SCHEMA schema_name 
 | AUTHORIZATION embedded_authorization_identifier _maybe_for_static_only_or_and_dynamic 
 | SCHEMA schema_name AUTHORIZATION embedded_authorization_identifier _maybe_for_static_only_or_and_dynamic
 ;

embedded_authorization_identifier:
 module_authorization_identifier
 ;

embedded_path_specification:
 path_specification
 ;

embedded_transform_group_specification:
 transform_group_specification
 ;

embedded_collation_specification:
 module_collations
 ;

# Modified
embedded_sql_declare_section:
# embedded_sql_begin_declare [ embedded_character_set_declaration ] [ host_variable_definition... ] embedded_sql_end_declare | embedded_sql_mumps_declare
 embedded_sql_begin_declare _maybe_embedded_character_set_declaration _maybe_host_variable_definition_multi embedded_sql_end_declare | embedded_sql_mumps_declare
 ;

# Added
_maybe_host_variable_definition_multi:
 | | | | | |
 host_variable_definition _maybe_host_variable_definition_multi
 ;
 
# Added
_maybe_embedded_character_set_declaration:
 | embedded_character_set_declaration
 ;

embedded_character_set_declaration:
 SQL NAMES ARE character_set_specification
 ;

# Modified
embedded_sql_begin_declare:
# sql_prefix begin declare section [ sql_terminator ]
 sql_prefix BEGIN DECLARE SECTION _maybe_sql_terminator
 ;

# Modified
embedded_sql_end_declare:
# sql_prefix end declare section [ sql_terminator ]
 sql_prefix END DECLARE SECTION _maybe_sql_terminator
 ;

# Modified
embedded_sql_mumps_declare:
# sql_prefix begin declare section [ embedded_character_set_declaration ] [ host_variable_definition... ] end declare section sql_terminator
 sql_prefix BEGIN DECLARE SECTION _maybe_embedded_character_set_declaration _maybe_host_variable_definition_multi END DECLARE SECTION sql_terminator
 ;

# TODO: PL/I
host_variable_definition:
 ada_variable_definition | c_variable_definition | cobol_variable_definition | fortran_variable_definition | mumps_variable_definition | pascal_variable_definition | pl_i variable definition
 ;
 
embedded_variable_name:
 :host_identifier
 ;

host_identifier:
 ada_host_identifier | c_host_identifier | cobol_host_identifier
 ;

embedded_exception_declaration:
 WHENEVER condition condition_action
 ;

condition:
 sql_condition
 ;

# Modified
sql_condition:
# major_category | sqlstate ( sqlstate_class_value [ , sqlstate_subclass_value ] ) | constraint constraint_name
   major_category 
 | SQLSTATE ( sqlstate_class_value _maybe_comma_sqlstate_subclass_value ) 
 | CONSTRAINT constraint_name
 ;
 
# Added
_maybe_comma_sqlstate_subclass_value:
 | , sqlstate_subclass_value
 ;

major_category:
   SQLEXCEPTION 
 | SQLWARNING 
 | NOT FOUND
 ;

sqlstate_class_value:
 sqlstate_char sqlstate_char
 # see the syntax rules.
 ;

sqlstate_subclass_value:
 sqlstate_char sqlstate_char sqlstate_char
 # see the syntax rules.
 ;

sqlstate_char:
 simple_latin_upper_case_letter | digit
 ;

condition_action:
 CONTINUE | go_to
 ;

# Modified
go_to:
# { goto | go TO } goto_target
 _goto_or_go_to goto_target
 ;
 
# Added
_goto_or_go_to:
 GOTO | GO TO
 ;

goto_target:
 host_label_identifier | unsigned_integer | host_pl_i label variable
 ;

host_label_identifier:
 # see the syntax rules.
 ;

embedded_sql_ada_program:
 # see the syntax rules.
 ;

# Modified
ada_variable_definition:
# ada_host_identifier [ { , ada_host_identifier }... ] colon ada_type_specification [ ada_initial_value ]
 ada_host_identifier _maybe_comma_ada_host_identifier_multi:ada_type_specification _maybe_ada_initial_value
 ;
 
# Added
_maybe_comma_ada_host_identifier_multi:
 | | | | | |
 , ada_host_identifier _maybe_comma_ada_host_identifier_multi
 ;
 
# Added
_maybe_ada_initial_value:
 | ada_initial_value
 ;

# Modified
ada_initial_value:
# ada_assignment_operator character_representation...
 _ada_assignment_operator_character_representation_multi
 ;
 
# Added
_ada_assignment_operator_character_representation_multi:
   ada_assigment operator character_representation
 | ada_assigment operator character_representation
 | ada_assigment operator character_representation
 | ada_assigment operator character_representation
 | ada_assigment operator character_representation
 | ada_assigment operator character_representation _ada_assignment_operator_character_representation_multi
 ;

ada_assignment_operator:
 :=
 ;

ada_host_identifier:
 # see the syntax rules.
 ;

ada_type_specification:
 ada_qualified_type_specification | ada_unqualified_type_specification | ada_derived_type_specification
 ;

# Modified
ada_qualified_type_specification:
# interfaces.sql.char [ character set [ is ] character_set_specification ] ( 1 double_period character_length ) | interfaces.sql.smallint | interfaces.sql.int | interfaces.sql.bigint | interfaces.sql.real | interfaces.sql.double_precision | interfaces.sql.boolean | interfaces.sql.sqlstate_type | interfaces.sql.indicator_type
 interfaces.sql.char _maybe_character_set_maybe_is_character_set_specification ( 1 double_period character_length ) | interfaces.sql.smallint | interfaces.sql.int | interfaces.sql.bigint | interfaces.sql.real | interfaces.sql.double_precision | interfaces.sql.BOOLEAN | interfaces.sql.sqlstate_type | interfaces.sql.indicator_type
 ;
 
# Added
_maybe_character_set_maybe_is_character_set_specification:
 | character_set _maybe_is character_set_specification
 ;
 
_maybe_is:
 | is
 ;

ada_unqualified_type_specification:
 CHAR ( 1 double_period character_length ) | smallint | int | bigint | real | double_precision | BOOLEAN | sqlstate_type | indicator_type
 ;

ada_derived_type_specification:
 ada_clob_variable | ada_clob_locator_variable | ada_binary_variable | ada_varbinary_variable | ada_blob_variable | ada_blob_locator_variable | ada_user_defined_type_variable | ada_user_defined_type_locator_variable | ada_ref_variable | ada_array_locator_variable | ada_multiset_locator_variable
 ;

# Modified
ada_clob_variable:
# sql type is clob ( character_large_object_length ) [ character set [ is ] character_set_specification ]
 sql type is clob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification
 ;

ada_clob_locator_variable:
 sql type is clob AS locator
 ;

ada_binary_variable:
 sql type is binary ( length ) ;

ada_varbinary_variable:
 sql type is varbinary ( length ) ;

ada_blob_variable:
 sql type is blob ( large_object_length ) ;

ada_blob_locator_variable:
 sql type is blob AS locator
 ;

ada_user_defined_type_variable:
 sql type is path_resolved_user_defined_type_name AS predefined_type
 ;

ada_user_defined_type_locator_variable:
 sql type is path_resolved_user_defined_type_name AS locator
 ;

ada_ref_variable:
 sql type is reference_type
 ;

ada_array_locator_variable:
 sql type is array_type AS locator
 ;

ada_multiset_locator_variable:
 sql type is multiset_type AS locator
 ;

embedded_sql_c_program:
 # see the syntax rules.
 ;

# Modified
c_variable_definition:
# [ c_storage_class ] [ c_class_modifier ] c_variable_specification semicolon
 _maybe_c_storage_class _maybe_c_class_modifier c_variable_specification semicolon
 ;
 
# Added
_maybe_c_class_modifier:
 | c_class_modifier
 ;
 
# Added
_maybe_c_storage_class:
 | c_storage_class
 ;

c_variable_specification:
 c_numeric_variable | c_character_variable | c_derived_variable
 ;

c_storage_class:
 auto | extern | static
 ;

c_class_modifier:
 const | volatile
 ;

# Modified
c_numeric_variable:
# { long long | long | short | float | double } c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 _long_long_or_long_or_short_or_float_or_double c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;
 
# Added
_maybe_comma_c_host_identifier_maybe_c_initial_value_multi:
 | | | | | |
 , c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;
 
# Added
_maybe_c_initial_value:
 | c_initial_value
 ;
 
# Added
_long_long_or_long_or_short_or_float_or_double:
 long long | long | short | float | double
 ;

# Modified
c_character_variable:
# c_character_type [ character set [ is ] character_set_specification ] c_host_identifier c_array_specification [ c_initial_value ] [ { , c_host_identifier c_array_specification [ c_initial_value ] }... ]
 c_character_type _maybe_character_set_maybe_is_character_set_specification c_host_identifier c_array_specification _maybe_c_initial_value _maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi
 ;
 
# Added
_maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi:
  | | | | | |
 , c_host_identifier c_array_specification _maybe_c_initial_value _maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi
  ;

c_character_type:
 char | unsigned char | unsigned short
 ;

c_array_specification:
 [ character_length right_bracket
 ;

c_host_identifier:
 # see the syntax rules.
 ;

# TODO
c_derived_variable:
 
 ;

# Modified
c_varchar_variable:
# varchar [ character set [ is ] character_set_specification ] c_host_identifier c_array_specification [ c_initial_value ] [ { , c_host_identifier c_array_specification [ c_initial_value ] }... ]
 varchar _maybe_character_set_maybe_is_character_set_specification c_host_identifier c_array_specification _maybe_c_initial_value _maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi
 ;

# Modified
c_nchar_variable:
# nchar [ character set [ is ] character_set_specification ] c_host_identifier c_array_specification [ c_initial_value ] [ { , c_host_identifier c_array_specification [ c_initial_value ] } ... ]
 nchar _maybe_character_set_maybe_is_character_set_specification c_host_identifier c_array_specification _maybe_c_initial_value _maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi
 ;

# Modified
c_nchar_varying_variable:
# nchar varying [ character set [ is ] character_set_specification ] c_host_identifier c_array_specification [ c_initial_value ] [ { , c_host_identifier c_array_specification [ c_initial_value ] } ... ]
 nchar varying _maybe_character_set_maybe_is_character_set_specification c_host_identifier c_array_specification _maybe_c_initial_value _maybe_comma_c_host_identifier_c_array_specification_maybe_c_initial_value_multi
 ;

# Modified
c_clob_variable:
# sql type is clob ( character_large_object_length ) [ character set [ is ] character_set_specification ] c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 sql type is clob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_nclob_variable:
# sql type is nclob ( character_large_object_length ) [ character set [ is ] character_set_specification ] c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 sql type is nclob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_user_defined_type_variable:
# sql type is path_resolved_user_defined_type_name as predefined_type c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is path_resolved_user_defined_type_name AS predefined_type c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_binary_variable:
# sql type is binary ( length ) c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 sql type is binary ( length ) c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

c_varbinary_variable:
 sql type is varbinary ( length ) ;

# Modified
c_blob_variable:
# sql type is blob ( large_object_length ) c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is blob ( large_object_length ) c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_clob_locator_variable:
# sql type is clob as locator c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is clob AS locator c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_blob_locator_variable:
# sql type is blob as locator c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is blob AS locator c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_array_locator_variable:
# sql type is array_type as locator c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is array_type AS locator c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_multiset_locator_variable:
# sql type is multiset_type as locator c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] } ... ]
 sql type is multiset_type AS locator c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_user_defined_type_locator_variable:
# sql type is path_resolved_user_defined_type_name as locator c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 sql type is path_resolved_user_defined_type_name AS locator c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified
c_ref_variable:
# sql type is reference_type c_host_identifier [ c_initial_value ] [ { , c_host_identifier [ c_initial_value ] }... ]
 sql type is reference_type c_host_identifier _maybe_c_initial_value _maybe_comma_c_host_identifier_maybe_c_initial_value_multi
 ;

# Modified 
c_initial_value:
# equals_operator character_representation...
 _equals_operator_character_representation_multi
 ;
 
# Added
_equals_operator_character_representation_multi:
   equals_operator character_representation
 | equals_operator character_representation
 | equals_operator character_representation
 | equals_operator character_representation
 | equals_operator character_representation
 | equals_operator character_representation _equals_operator_character_representation_multi
 ;

embedded_sql_cobol_program:
 # see the syntax rules.
 ;

# Modified
cobol_variable_definition:
# { 01 |77 } cobol_host_identifier cobol_type_specification [ character_representation... ] period
 _01_or_77 cobol_host_identifier cobol_type_specification _maybe_character_representation_multi .
 ;
 
# Added
_maybe_character_representation_multi:
 | | | | | |
 character_representation _maybe_character_representation_multi
 ;
 
# Added
_01_or_77:
 01 | 77
 ;

cobol_host_identifier:
 # see the syntax rules.
 ;

cobol_type_specification:
 cobol_character_type | cobol_national_character_type | cobol_numeric_type | cobol_integer_type | cobol_derived_type_specification
 ;

cobol_derived_type_specification:
 cobol_clob_variable | cobol_nclob_variable | cobol_binary_variable | cobol_blob_variable | cobol_user_defined_type_variable | cobol_clob_locator_variable | cobol_blob_locator_variable | cobol_array_locator_variable | cobol_multiset_locator_variable | cobol_user_defined_type_locator_variable | cobol_ref_variable
 ;

# Modified
cobol_character_type:
# [ character set [ is ] character_set_specification ] { pic | picture } [ is ] { x [ ( character_length ) ] }...
 _maybe_character_set_maybe_is_character_set_specification _pic_or_picture _maybe_is _x_maybe_left_paren_character_length_right_paren_multi
 ;
 
# Added
_x_maybe_left_paren_character_length_right_paren_multi:
   x _maybe_left_paren_character_length_right_paren
 | x _maybe_left_paren_character_length_right_paren
 | x _maybe_left_paren_character_length_right_paren
 | x _maybe_left_paren_character_length_right_paren
 | x _maybe_left_paren_character_length_right_paren
 | x _maybe_left_paren_character_length_right_paren _x_maybe_left_paren_character_length_right_paren_multi
 ;
 
# Added
_pic_or_picture:
 pic | picture
 ;

# Modified
cobol_national_character_type:
# [ character set [ is ] character_set_specification ] { pic | picture } [ is ] { n [ ( character_length ) ] }...
 _maybe_character_set_maybe_is_character_set_specification _pic_or_picture _maybe_is _n_maybe_left_paren_character_length_right_paren_multi
 ;
 
# Added
_n_maybe_left_paren_character_length_right_paren_multi:
   N _maybe_left_paren_character_length_right_paren 
 | N _maybe_left_paren_character_length_right_paren 
 | N _maybe_left_paren_character_length_right_paren 
 | N _maybe_left_paren_character_length_right_paren 
 | N _maybe_left_paren_character_length_right_paren 
 | N _maybe_left_paren_character_length_right_paren _n_maybe_left_paren_character_length_right_paren_multi
 ;

# Modified
cobol_clob_variable:
# [ usage [ is ] ] sql type is clob ( character_large_object_length ) [ character set [ is ] character_set_specification ]
 _maybe_usage_maybe_is sql type is clob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification
 ;

# Added
_maybe_usage_maybe_is:
 | usage _maybe_is _maybe_usage_maybe_is
 ;
 
# TODO
cobol_nclob_variable:
 
 ;

# Modified
cobol_binary_variable:
# [ usage [ is ] ] sql type is binary ( length ) _maybe_usage_maybe_is sql type is binary ( length ) ;

# Modified
cobol_blob_variable:
# [ usage [ is ] ] sql type is blob ( large_object_length ) _maybe_usage_maybe_is sql type is blob ( large_object_length ) ;

# Modified
cobol_user_defined_type_variable:
# [ usage [ is ] ] sql type is path_resolved_user_defined_type_name as predefined_type
 _maybe_usage_maybe_is sql type is path_resolved_user_defined_type_name AS predefined_type
 ;

# Modified
cobol_clob_locator_variable:
# [ usage [ is ] ] sql type is clob as locator
 _maybe_usage_maybe_is sql type is clob AS locator
 ;

# Modified
cobol_blob_locator_variable:
# [ usage [ is ] ] sql type is blob as locator
 _maybe_usage_maybe_is sql type is blob AS locator
 ;

# Modified
cobol_array_locator_variable:
# [ usage [ is ] ] sql type is array_type as locator
 _maybe_usage_maybe_is sql type is array_type AS locator
 ;

# Modified
cobol_multiset_locator_variable:
# [ usage [ is ] ] sql type is multiset_type as locator
 _maybe_usage_maybe_is sql type is multiset_type AS locator
 ;

# Modified
cobol_user_defined_type_locator_variable:
# [ usage [ is ] ] sql type is path_resolved_user_defined_type_name as locator
 _maybe_usage_maybe_is sql type is path_resolved_user_defined_type_name AS locator
 ;

# Modified
cobol_ref_variable:
# [ usage [ is ] ] sql type is reference_type
 _maybe_usage_maybe_is sql type is reference_type
 ;

# Modified
cobol_numeric_type:
# { pic | picture } [ is ] s cobol_nines_specification [ usage [ is ] ] display sign leading separate
 _pic_or_picture _maybe_is s cobol_nines_specification _maybe_usage_maybe_is display sign leading separate
 ;

# Modified
cobol_nines_specification:
# cobol_nines [ v [ cobol_nines ] ] | v cobol_nines
 cobol_nines _maybe_v_maybe_cobol_nines | v cobol_nines
 ;
 
# Added
_maybe_v_maybe_cobol_nines:
 | v _maybe_cobol_nines
 ;
 
# Added
_maybe_cobol_nines:
 | cobol_nines
 ;

# Modified
cobol_integer_type:
# { pic | picture } [ is ] s cobol_nines [ usage [ is ] ] binary
 _pic_or_picture _maybe_is s cobol_nines _maybe_usage_maybe_is binary
 ;

# Modified
cobol_nines:
# { 9 [ ( length ) ] }...
 _9_maybe_left_paren_length_right_paren_multi
 ;
 
# Added
_9_maybe_left_paren_length_right_paren_multi:
   9 _maybe_left_paren_length_right_paren
 | 9 _maybe_left_paren_length_right_paren
 | 9 _maybe_left_paren_length_right_paren
 | 9 _maybe_left_paren_length_right_paren
 | 9 _maybe_left_paren_length_right_paren
 | 9 _maybe_left_paren_length_right_paren _9_maybe_left_paren_length_right_paren_multi
 ;

embedded_sql_fortran_program:
 # see the syntax rules.
 ;

# Modified
fortran_variable_definition:
# fortran_type_specification fortran_host_identifier [ { , fortran_host_identifier }... ]
 fortran_type_specification fortran_host_identifier _maybe_comma_fortran_host_identifier_multi
 ;
 
# Added
_maybe_comma_fortran_host_identifier_multi:
 | | | | | |
 , fortran_host_identifier _maybe_comma_fortran_host_identifier_multi
 ;

fortran_host_identifier:
 # see the syntax rules.
 ;

# Modified
fortran_type_specification:
# character [ * character_length ] [ character set [ is ] character_set_specification ] | character kind = n [ * character_length ] [ character set [ is ] character_set_specification ] | integer | real | double precision | logical | fortran_derived_type_specification
 character _maybe_asterisk_character_length _maybe_character_set_character_set_specification | character kind = N _maybe_asterisk_character_length _maybe_character_set_maybe_is_character_set_specification | integer | real | double precision | logical | fortran_derived_type_specification
 ;
 
_maybe_asterisk_character_length:
 | * character_length
 ;

fortran_derived_type_specification:
 fortran_clob_variable | fortran_binary_variable | fortran_varbinary_variable | fortran_blob_variable | fortran_user_defined_type_variable | fortran_clob_locator_variable | fortran_blob_locator_variable | fortran_user_defined_type_locator_variable | fortran_array_locator_variable | fortran_multiset_locator_variable | fortran_ref_variable
 ;

# Modified
fortran_clob_variable:
# sql type is clob ( character_large_object_length ) [ character set [ is ] character_set_specification ]
 sql type is clob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification
 ;

fortran_binary_variable:
 sql type is binary ( length ) ;

fortran_varbinary_variable:
 sql type is varbinary ( length ) ;

fortran_blob_variable:
 sql type is blob ( large_object_length ) ;

fortran_user_defined_type_variable:
 sql type is path_resolved_user_defined_type_name AS predefined_type
 ;

fortran_clob_locator_variable:
 sql type is clob AS locator
 ;

fortran_blob_locator_variable:
 sql type is blob AS locator
 ;

fortran_user_defined_type_locator_variable:
 sql type is path_resolved_user_defined_type_name AS locator
 ;

fortran_array_locator_variable:
 sql type is array_type AS locator
 ;

fortran_multiset_locator_variable:
 sql type is multiset_type AS locator
 ;

fortran_ref_variable:
 sql type is reference_type
 ;

embedded_sql_mumps_program:
 # see the syntax rules.
 ;

mumps_variable_definition:
 mumps_numeric_variable semicolon | mumps_character_variable semicolon | mumps_derived_type_specification mumps_host_identifier semicolon
 ;

# Modified
mumps_character_variable:
# varchar mumps_character_variable_specifier [ { , mumps_character_variable_specifier }... ]
 varchar mumps_character_variable_specifier _maybe_comma_mumps_character_variable_specifier_multi
 ;
 
# Added
_maybe_comma_mumps_character_variable_specifier_multi:
 | | | | | |
 , mumps_character_variable_specifier _maybe_comma_mumps_character_variable_specifier_multi
 ;

# Modified
mumps_character_variable_specifier:
# mumps_host_identifier mumps_length_specification [ character set [ is ] character_set_specification ]
 mumps_host_identifier mumps_length_specification _maybe_character_set_maybe_is_character_set_specification
 ;

mumps_host_identifier:
 # see the syntax rules.
 ;

mumps_length_specification:
 ( character_length ) ;

# Modified
mumps_numeric_variable:
# mumps_type_specification mumps_host_identifier [ { , mumps_host_identifier }... ]
 mumps_type_specification mumps_host_identifier _maybe_comma_mumps_host_identifier_multi
 ;
 
# Added
_maybe_comma_mumps_host_identifier_multi:
 | | | | | |
 , mumps_host_identifier _maybe_comma_mumps_host_identifier_multi
 ;

# Modified
mumps_type_specification:
# int | dec [ ( precision [ , scale ] ) ] | real
 int | dec _left_paren_precision_maybe_comma_scale_right_paren | real
 ;
 
# Added
_left_paren_precision_maybe_comma_scale_right_paren:
 | ( precision _maybe_comma_scale ) | ( precision _maybe_comma_scale )
mumps_derived_type_specification:
 mumps_user_defined_type_variable | mumps_clob_locator_variable | mumps_blob_locator_variable | mumps_user_defined_type_locator_variable | mumps_array_locator_variable | mumps_multiset_locator_variable | mumps_ref_variable
 ;

mumps_user_defined_type_variable:
 sql type is path_resolved_user_defined_type_name AS predefined_type
 ;

mumps_clob_locator_variable:
 sql type is clob AS locator
 ;

mumps_blob_locator_variable:
 sql type is blob AS locator
 ;

mumps_user_defined_type_locator_variable:
 sql type is path_resolved_user_defined_type_name AS locator
 ;

mumps_array_locator_variable:
 sql type is array_type AS locator
 ;

mumps_multiset_locator_variable:
 sql type is multiset_type AS locator
 ;

mumps_ref_variable:
 sql type is reference_type
 ;

embedded_sql_pascal_program:
 # see the syntax rules.
 ;

# Modified
pascal_variable_definition:
# pascal_host_identifier [ { , pascal_host_identifier }... ] colon pascal_type_specification semicolon
 pascal_host_identifier _maybe_comma_pascal_host_identifier_multi : pascal_type_specification semicolon
 ;
 
# Added
_maybe_comma_pascal_host_identifier_multi:
 | | | | | |
 , pascal_host_identifier _maybe_comma_pascal_host_identifier_multi
 ;

pascal_host_identifier:
 # see the syntax rules.
 ;

# Modified
pascal_type_specification:
# packed array [ 1 double_period character_length ] of char [ character set [ is ] character_set_specification ] | integer | real | char [ character set [ is ] character_set_specification ] | boolean | pascal_derived_type_specification
 PACKED ARRAY [ 1 double_period character_length ] of char _maybe_character_set_maybe_is_character_set_specification | integer | real | char _maybe_character_set_maybe_is_character_set_specification | BOOLEAN | pascal_derived_type_specification
 ;

pascal_derived_type_specification:
 pascal_clob_variable | pascal_binary_variable | pascal_blob_variable | pascal_user_defined_type_variable | pascal_clob_locator_variable | pascal_blob_locator_variable | pascal_user_defined_type_locator_variable | pascal_array_locator_variable | pascal_multiset_locator_variable | pascal_ref_variable
 ;

# Modified
pascal_clob_variable:
# sql type is clob ( character_large_object_length ) [ character set [ is ] character_set_specification ]
 sql type is clob ( character_large_object_length ) _maybe_character_set_maybe_is_character_set_specification
 ;

pascal_binary_variable:
 sql type is binary ( length ) ;

pascal_blob_variable:
 sql type is blob ( large_object_length ) ;

pascal_clob_locator_variable:
 sql type is clob AS locator
 ;

pascal_user_defined_type_variable:
 sql type is path_resolved_user_defined_type_name AS predefined_type
 ;

pascal_blob_locator_variable:
 sql type is blob AS locator
 ;

pascal_user_defined_type_locator_variable:
 sql type is path_resolved_user_defined_type_name AS locator
 ;

pascal_array_locator_variable:
 sql type is array_type AS locator
 ;

pascal_multiset_locator_variable:
 sql type is multiset_type AS locator
 ;

pascal_ref_variable:
 sql type is reference_type
 ;

direct_sql_statement:
 directly_executable_statement semicolon
 ;

directly_executable_statement:
 direct_sql_data_statement | sql_schema_statement | sql_transaction_statement | sql_connection_statement | sql_session_statement | direct_implementation_defined_statement
 ;

direct_sql_data_statement:
 delete_statement__searched | direct_select_statement__multiple_rows | insert_statement | update_statement__searched | truncate_table_statement | merge_statement | temporary_table_declaration
 ;

direct_implementation_defined_statement:
 # see the syntax rules.
 ;
 
direct_select_statement__multiple_rows:
 cursor_specification
 ;

get_diagnostics_statement:
 GET DIAGNOSTICS sql_diagnostics_information
 ;

sql_diagnostics_information:
 statement_information | condition_information | all_information
 ;

# Modified
statement_information:
# statement_information_item [ { , statement_information_item }... ]
 statement_information_item _maybe_comma_statement_information_item_multi
 ;
 
# Added
_maybe_comma_statement_information_item_multi:
 | | | | | |
 , statement_information_item _maybe_comma_statement_information_item_multi
 ;

statement_information_item:
 simple_target_specification equals_operator statement_information_item_name
 ;

statement_information_item_name:
   NUMBER 
 | MORE 
 | COMMAND_FUNCTION 
 | COMMAND_FUNCTION_CODE 
 | DYNAMIC_FUNCTION 
 | DYNAMIC_FUNCTION_CODE 
 | ROW_COUNT 
 | TRANSACTIONS_COMMITTED 
 | TRANSACTIONS_ROLLED_BACK 
 | TRANSACTION_ACTIVE
 ;

# Modified
condition_information:
# condition condition_number condition_information_item [ { , condition_information_item }... ]
 condition condition_number condition_information_item _maybe_comma_condition_information_item_multi
 ;
 
# Added
_maybe_comma_condition_information_item_multi:
 | | | | | |
 , condition_information_item _maybe_comma_condition_information_item_multi
 ;

condition_information_item:
 simple_target_specification equals_operator condition_information_item_name
 ;

condition_information_item_name:
   CATALOG_NAME 
 | CLASS_ORIGIN 
 | COLUMN_NAME 
 | CONDITION_NUMBER 
 | CONNECTION_NAME 
 | CONSTRAINT_CATALOG 
 | CONSTRAINT_NAME 
 | CONSTRAINT_SCHEMA 
 | CURSOR_NAME 
 | MESSAGE_LENGTH 
 | MESSAGE_OCTET_LENGTH 
 | MESSAGE_TEXT 
 | PARAMETER_MODE 
 | PARAMETER_NAME 
 | PARAMETER_ORDINAL_POSITION 
 | RETURNED_SQLSTATE 
 | ROUTINE_CATALOG 
 | ROUTINE_NAME 
 | ROUTINE_SCHEMA 
 | SCHEMA_NAME 
 | SERVER_NAME 
 | SPECIFIC_NAME 
 | SUBCLASS_ORIGIN 
 | TABLE_NAME 
 | TRIGGER_CATALOG 
 | TRIGGER_NAME 
 | TRIGGER_SCHEMA
 ;

# Modified
all_information:
# all_info_target equals_operator all [ all_qualifier ]
 all_info_target equals_operator all _maybe_all_qualifier
 ;
 
# Added
_maybe_all_qualifier:
 | all_qualifier
 ;

all_info_target:
 simple_target_specification
 ;

# Modified
all_qualifier:
# statement | condition [ condition_number ]
 statement | condition _maybe_condition_number
 ;
 
# Added
_maybe_condition_number:
 | condition_number
 ;

condition_number:
 simple_value_specification
 ;

