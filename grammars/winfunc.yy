query:
	select ;
# | update | delete | create | insert ;

select:
	SELECT window_function FROM _table ;

update:
	;

delete:
	;

insert:
	;

create:
	;

window_function:
	window_function_type OVER ( window_name_or_specification );

# TODO: NTH not supported ?
window_function_type:
	rank_func_type() |
	ROW_NUMBER() |
	aggregate_function |
	ntile_func |
	lead_or_lag_func |
	first_or_last_val_func ;
#	nth_val_func ;

aggregate_function:
	aggregate_function_2 filter_clause ;

aggregate_function_2:
	COUNT(*) |
	general_set_function |
	binary_set_function |
	ordered_set_function |
	array_aggregate_function ;

array_aggregate_function:
	ARRAY_AGG( value_expression order_by_sort_specification_list );

order_by_sort_specification_list:
	| | ORDER BY sort_specification_list ;

general_set_function:
	set_function_type( set_quantifier value_expression );

set_function_type:
	computational_operation;

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
	| | DISTINCT | ALL ;

# TODO: we don't have FILTER 
filter_clause:
#	| | FILTER( WHERE search_condition ) ;
	WHERE search_condition ;

search_condition:
	boolean_value_expression ;

boolean_value_expression:
	  boolean_term
	| boolean_value_expression OR boolean_term
	;

boolean_term:
	  boolean_factor
	| boolean_term AND boolean_factor
	;

boolean_factor:
	not boolean_test ;

# TODO
not:
	;
#	| NOT ;

boolean_test:
	boolean_primary is_not_truth_value ;

is_not_truth_value:
	| IS not truth_value ;

truth_value:
	  TRUE 
	| FALSE
	| UNKNOWN
	;

boolean_primary:
	  predicate
	| boolean_predicand 
	;

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
	| unique_predicate
	| normalized_predicate
	| match_predicate
	| overlaps_predicate
	| distinct_predicate
	| member_predicate
	| submultiset_predicate
	| set_predicate
	| type_predicate
	| period_predicate
	;

boolean_predicand:
	  parenthesized_boolean_value_expression
	| nonparenthesized_value_expression_primary
	;

parenthesized_boolean_value_expression:
	( boolean_value_expression ) ;

binary_set_function:
	binary_set_function_type( dependent_variable_expression , independent_variable_expression );

dependent_variable_expression:
	numeric_value_expression ;

independent_variable_expression:
	numeric_value_expression ;

binary_set_function_type:
	  COVAR_POP
	| COVAR_SAMP
	| CORR
	| REGR_SLOPE
	| REGR_INTERSEPT
	| REGR_COUNT
	| REGR_R2
	| REGR_AVGX
	| REGR_AVGY
	| REGR_SXX
	| REGR_SYY
	| REGR_SXY
	;



rank_func_type:
	RANK | DENSE_RANK | PERCENT_RANK | CUME_DIST ;

ntile_func:
	NTILE( number_of_tiles ) ;

# TODO: later
number_of_tiles:
	simple_value_specification ;
# | dynamic_parameter_specification ;

dynamic_parameter_specification:
	? ;

# TODO: not supported? 
null_treatment:
	;
#	| | | RESPECT NULLS | IGNORE NULLS ;

# TODO: if it works, there is more syntax
lead_or_lag_func:
	lead_or_lag( lead_or_lag_extent ) null_treatment ;

lead_or_lag:
	LEAD | LAG ;

lead_or_lag_extent:
	value_expression ;

first_or_last_val_func:
	first_or_last_val( value_expression ) null_treatment ;

first_or_last_val:
	FIRST_VALUE | LAST_VALUE ;

nth_val_func:
	NTH_VALUE( value_expression , nth_row ) from_first_to_last null_treatment ;

nth_row:
	simple_value_specification | dynamic_parameter_specification ;

from_first_to_last:
	| | | FROM FIRST | FROM LAST ;

window_name_or_specification:
	# window_name | 
	inline_window_specification ;

# TODO: how to name a window?
window_name:
	_char(16) ;

inline_window_specification:
	window_specification ;

# TODO
window_specification:
	window_specification_details;

window_specification_details:
	existing_window_name window_partition_clause window_order_clause window_frame_clause ;

# TODO:
existing_window_name:
	;
#	| | window_name;

# TODO
window_partition_clause:
    |
	PARTITION BY ( window_partition_column_reference_list );

# TODO
window_partition_column_reference_list:
    |
	window_partition_column_reference | window_partition_column_reference_list , window_partition_column_reference ;

window_partition_column_reference:
	column_reference collate_clause ;

column_reference:
	_field ;

collate_clause:
	| | | COLLATE collation_name;

# TODO: more
collation_name:
	utf8_general_ci | latin1_general_ci;

window_order_clause:
	| ORDER BY sort_specification_list ;

window_frame_clause:
	| window_frame_units window_frame_extent window_frame_exclusion ;

# TODO: GROUPS not supported
window_frame_units:
	ROWS | RANGE ;
#| GROUPS ;

window_frame_extent:
	window_frame_start | window_frame_between ;

window_frame_start:
	UNBOUNDED PRECEDING | window_frame_preceding | CURRENT ROW ;

# TODO: MDEV-9896 Note 1
window_frame_preceding:
#	unsigned_value_specification PRECEDING ;
	unsigned_literal PRECEDING ;

window_frame_between:	
	BETWEEN window_frame_bound AND window_frame_bound ;

window_frame_bound:
	window_frame_start | UNBOUNDED FOLLOWING | window_frame_following ;

window_frame_following:
	unsigned_value_specification FOLLOWING ;

# TODO: Not supported ?
window_frame_exclusion:
	;
#	EXCLUDE CURRENT ROW | EXCLUDE GROUP | EXCLUDE TILES | EXCLUDE NO OTHERS ;

# TODO
simple_value_specification:
	literal ;
	# | host_parameter_name | sql_parameter_reference | embedded_variable_name ;

literal:
	_int | _string | _char(16) | _tinyint_unsigned | _digit ;

sort_specification_list:
	sort_specification | sort_specification_list , sort_specification ;

sort_specification:
	sort_key ordering_specification null_ordering ;

ordering_specification:
	| ASC | DESC ;

# TODO: not supported
null_ordering:
	;
#	| | NULLS FIRST | NULLS LAST ;

sort_key:
	value_expression ;

value_expression:
	common_value_expression | boolean_value_expression | row_value_expression ;

common_value_expression:
	numeric_value_expression |
	string_value_expression |
	datetime_value_expression |
	interval_value_expression |
	user_defined_type_value_expression |
	reference_value_expression |
	collection_value_expression ;

user_defined_type_value_expression:
	value_expression_primary;

value_expression_primary:
	  parenthesized_value_expression 
	| nonparenthesized_value_expression_primary ;

parenthesized_value_expression:
	( value_expression ) ;

# TODO: later (loop)
collection_value_expression:
	array_value_expression ;
#| multiset_value_expression ;

multiset_value_expression:
	  multiset_term
	| multiset_value_expression MULTISET UNION all_distinct multiset_term
	| multiset_value_expression MULTISET EXCEPT all_distinct multiset_term
	;

multiset_term:
	  multiset_primary
	| multiset_term MULTISET INTERSECT all_distinct multiset_primary 
	;

multiset_primary:
	  multiset_value_function
	| value_expression_primary
	;

multiset_value_function:
	multiset_set_function ;

multiset_set_function:
	SET ( multiset_value_expression ) ;

all_distinct:
	| | ALL | DISTINCT ;

# TODO: 
numeric_value_expression:
	_int | _tinyint_unsigned | _digit ;

# TODO:
string_value_expression:
	_string | _char(1) | _char(16) ;

# TODO:
datetime_value_expression:
	'2012-12-21 12:12:12' | NOW() ;

interval_value_expression:
	interval_term | 
	interval_value_expression + interval_term |
	interval_value_expression - interval_term |
	( datetime_value_expression - datetime_term ) interval_qualifier ;

interval_term:
	interval_factor | 
	interval_term * factor |
	interval_term / factor |
	term * interval_factor ;

interval_factor:
	sign interval_primary ;

# TODO: check
sign:
	| | | + | - ;

interval_primary:
	value_expression_primary interval_qualifier | interval_value_function ;

interval_qualifier:
	|
	start_field TO end_field |
	single_datetime_field ;

# TODO
single_datetime_field:
	_field ;

# TODO
start_field:
	_field ;

# TODO
end_field:
	_field ;

unsigned_value_specification:
	unsigned_literal | general_value_specification ;

general_value_specification:
	host_parameter_specification |
	sql_parameter_reference |
	dynamic_parameter_specification |
	embedded_variable_specification |
	current_collation_specification |
	CURRENT_CATALOG |
#	CURRENT_DEFAULT_TRANSFORM_GROUP |
	CURRENT_PATH |
	CURRENT_ROLE |
#	CURRENT_SCHEMA |
	DATABASE() |
	CURRENT_TRANSFORM_GROUP_FOR_TYPE path_resolved_user_defined_type_name |
	CURRENT_USER |
	SESSION_USER |
#	SYSTEM_USER |
	SYSTEM_USER() |
	USER 
#	| VALUE 
;

unsigned_literal:
	unsigned_numeric_literal |
	general_literal ;

general_literal:
	character_string_literal |
	national_character_string_literal |
	unicode_character_string_literal |
	binary_string_literal |
	datetime_literal |
	interval_literal |
	boolean_literal ;

interval_literal:
	INTERVAL sign interval_string interval_qualifier ;

interval_string:
	_string | _char(8) ;



# TODO
unicode_character_string_literal:
	_char(1) | _char(8) | _char(256);

# TODO
character_string_literal:
	_char(1) | _char(16) ;

unsigned_numeric_literal:
	exact_numeric_literal | approximate_numeric_literal ;

# TODO
exact_numeric_literal:
	_int_unsigned ;

row_value_expression:
	row_value_special_case | explicit_row_value_constructor ;

row_value_special_case:
	nonparenthesized_value_expression_primary ;

# I am here now
nonparenthesized_value_expression_primary:
	  unsigned_value_specification
	; 

explicit_row_value_constructor:
	  ( row_value_constructor_element , row_value_constructor_element_list ) 
	| ROW( row_value_constructor_element_list )
	| row_subquery 
	;

row_value_constructor_element_list:
	row_value_constructor_element | row_value_constructor_element , row_value_constructor_element_list ;

row_value_constructor_element:
	value_expression ;

# TODO
approximate_numeric_literal:
	CONCAT(mantissa, 'E', exponent);

mantissa:
	exact_numeric_literal;

exponent:
	_int ;

