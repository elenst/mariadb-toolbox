# Copyright (C) 2013 Monty Program Ab
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

query:
	alter | alter | optimize | rename | select_ft | select_is ;

select_is:
	SELECT * FROM INFORMATION_SCHEMA . is_table ;

is_table:
	INNODB_SYS_INDEXES | INNODB_SYS_TABLES | INNODB_FT_CONFIG | INNODB_FT_INDEX_TABLE | INNODB_FT_INDEX_CACHE | INNODB_FT_DEFAULT_STOPWORD | INNODB_FT_DELETED | INNODB_FT_BEING_DELETED ;

select_ft:
	SELECT select_item FROM _table WHERE match_clause select_order_by LIMIT _digit ;

select_item:
	* | _field | match_clause | COUNT(*) ;

match_clause:
	MATCH( match_list ) AGAINST ( _english search_modifier ) ;

search_modifier:
	| IN NATURAL LANGUAGE MODE | IN NATURAL LANGUAGE MODE WITH QUERY EXPANSION | IN BOOLEAN MODE | WITH QUERY EXPANSION ;

match_list:
	_field | _field , match_list ;

select_order_by:
	| ORDER BY _field ;

alter:
	ALTER online ignore TABLE _table alter_clause ;

online:
	| ONLINE ;

ignore:
	| | | IGNORE ;

alter_clause:
	order_by | alter_spec | alter_spec, alter_clause ;

optimize:
	OPTIMIZE TABLE _table ;

alter_spec:
	add_drop_column |
	drop_add_pk |
	drop_add_index |
	set_charset |
	FORCE ;


drop_add_pk:
	DROP PRIMARY KEY | ADD PRIMARY KEY (`pk`);

drop_add_index:
	DROP INDEX _field_key[invariant] | ADD index_type INDEX ( _field_key[invariant] ) ; 

index_type:
	| FULLTEXT ;

rename:
	RENAME TABLE _table[invariant] TO { "renamed_to_$$" } ; RENAME TABLE { "renamed_to_$$" } TO _table[invariant] ;

order_by:
	ORDER BY _field | ORDER BY _field, _field ;

set_charset:
	CONVERT TO CHARACTER SET charset | CHARACTER SET charset ;

charset:
	utf8 | latin1 ;

add_drop_column:
	ADD { "a$$" } column_type column_position, work_on_column, DROP { "a$$" } 
	| ADD ( { "a$$" } column_type, { "b$$" } column_type ) , DROP { "a$$" } , DROP { "b$$" } ;

work_on_column:
	alter_column |
	change_column |
	modify_column ;

alter_column:
	ALTER { "a$$" } SET DEFAULT '0' ;

change_column:
	CHANGE { "a$$" } { "c$$" } INT , CHANGE { "c$$" } { "a$$" } TEXT ;

modify_column:
	MODIFY { "a$$" } INT NOT NULL DEFAULT '1' ;

column_type:
	INT | TEXT ;

column_position:
	| FIRST | AFTER _field ;


