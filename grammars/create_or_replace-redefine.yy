thread8:
	create_or_replace_table;

thread7:
	create_or_replace_table;

thread6:
	create_or_replace_table;

create_or_replace_table:
	CREATE OR REPLACE TEMPORARY TABLE `tmp` AS SELECT * FROM _table[invariant] ; CREATE OR REPLACE table_view _table[invariant] AS SELECT * FROM `tmp` ;

table_view:
	TABLE | TABLE | TABLE | VIEW ;

