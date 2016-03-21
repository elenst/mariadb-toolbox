thread1:
	# Restore current user if it was dropped or renamed 
	GRANT ALL ON *.* TO _current_user WITH GRANT OPTION |
	query ;

# TODO: without RENAME USER (rename) for now, MDEV-8614 
query:
	create | drop | grant | revoke | set_password | i_s | set_role | create_drop_table_schema | flush_privs ;

flush_privs:
	FLUSH PRIVILEGES ;

set_password:
	SET PASSWORD for_user = PASSWORD(_english);

for_user:
	| FOR full_name ;

set_role:
	SET default ROLE name | 
	SET DEFAULT ROLE name FOR full_name ;

default:
	| | DEFAULT ;

i_s:
	SELECT * FROM INFORMATION_SCHEMA.APPLICABLE_ROLES |
	SELECT * FROM INFORMATION_SCHEMA.ENABLED_ROLES ;

create:
	CREATE or_replace USER name_list | CREATE USER if_not_exists identified_name_list |
	CREATE or_replace ROLE first_name_list | CREATE ROLE if_not_exists first_name_list ;

identified_name_list:
	full_name identified | full_name identified , identified_name_list ;

name_list:
	full_name | full_name , name_list ;

first_name_list:
	name | name , first_name_list ;

drop:
	DROP USER name_list | 
	DROP ROLE first_name_list ;

rename:
	RENAME USER rename_list ;

rename_list:
	full_name TO full_name | full_name TO full_name, rename_list ;

or_replace:
	| OR REPLACE ;

if_not_exists:
	| IF NOT EXISTS ;

if_exists:
	| IF EXISTS ;

full_name:
	name | name@host ;

name:
	_english | _english | 
	_char(8) | _char(80) |
	_letter | _letter | 
	ascii_printable | 
	unicode | 
	special_name ;

special_name:
	CURRENT_USER | CURRENT_ROLE | NONE | NULL | 'none' | 'null' | 'current_user' | 'current_role' ;

host:
	'' | '%' | localhost | '127.0.0.1' | 'home' | _english | _char(8) | _char(60) ;

identified:
	| | IDENTIFIED BY password _english | IDENTIFIED VIA plugin ;

plugin:
	'auth_pam' | _english ;

password:
	| PASSWORD ;


unicode:
# TODO: cannot use 0 character, MDEV-8612
#	{ $length = int(rand(80))+1; $comment = ''; $str = ''; foreach (1..$length) { $c = int(rand(65536)); $comment.= '-'.$c; $str .= chr($c) }; "/* $comment */ '" . $str . "'" }  ;
	{ $length = int(rand(80))+1; $comment = ''; $str = ''; foreach (1..$length) { $c = int(rand(65535))+1; if ($c == ord("'") or $c == ord('"')) { $comment .= ord('\\'); $str .= '\\' } ; $comment.= '-'.$c; $str .= chr($c) }; "/* $comment */ '" . $str . "'" }  ;

ascii_printable:
	{ $length = int(rand(81)); $comment = ''; $str = ''; foreach (1..$length) { $c = int(rand(86))+32; if ($c == ord("'") or $c == ord('"')) { $comment .= ord('\\'); $str .= '\\' } ;$comment.= '-'.$c; $str .= chr($c) }; "/* $comment */ '" . $str . "'" }  ;

revoke:
	revoke_privileges | revoke_privileges | revoke_privileges | revoke_privileges | revoke_privileges | 
	revoke_role | revoke_role | revoke_role | revoke_role | revoke_role | 
	revoke_proxy | 
	revoke_all | revoke_all ;

revoke_role:
	REVOKE name FROM name_list ;

revoke_privileges:
	REVOKE priv_list ON object_type priv_level FROM name_list ;

revoke_proxy:
	REVOKE PROXY ON full_name FROM name_list ;

revoke_all:
	REVOKE ALL PRIVILEGES, GRANT OPTION FROM name_list ;

grant:
	grant_privileges | grant_privileges | grant_privileges | grant_privileges | grant_privileges | 
	grant_role | grant_role | grant_role | grant_role | grant_role |
	grant_proxy ;

grant_role:
	GRANT name TO full_name admin_option ;

admin_option:
	| WITH ADMIN OPTION ;

grant_proxy:
	GRANT PROXY ON full_name TO name_list grant_option ;

grant_privileges:
	GRANT priv_list ON object_type priv_level TO identified_name_list require_ssl extra_options |
	GRANT col_priv_list ON TABLE priv_level TO identified_name_list require_ssl extra_options ;
    
priv_list:
	priv_type | priv_type, priv_list;

col_priv_list:
	col_priv_type | col_priv_type, col_priv_list;

priv_type:
	# Global
	CREATE TABLESPACE | CREATE USER | FILE | PROCESS | RELOAD | REPLICATION CLIENT | REPLICATION SLAVE | SHOW DATABASES | SHUTDOWN | SUPER |
	# Database
	CREATE | DROP | EVENT | GRANT OPTION | LOCK TABLES | REFERENCES |
	# Table
	ALTER | CREATE VIEW | CREATE | DELETE | DROP | GRANT OPTION | INDEX | INSERT | REFERENCES | SELECT | SHOW VIEW | TRIGGER | UPDATE |
	# Stored routine
	ALTER ROUTINE | EXECUTE | GRANT OPTION | CREATE ROUTINE 
;

col_priv_type:
	# Column
	INSERT column_list | REFERENCES column_list | SELECT column_list | UPDATE column_list ;

column_list:
	| | | ( col_names ) ;

col_names:
	col_name | col_name, col_names ;

object_type:
	TABLE | FUNCTION | PROCEDURE ;

priv_level:
    *
  | *.*
  | db_name.*
  | db_name.tbl_name
  | tbl_name
  | db_name.routine_name
;

require_ssl:
	| | REQUIRE ssl | REQUIRE ssl_option_list ;

ssl:
	NONE | SSL | X509 ;

ssl_option_list:
	ssl_option | ssl_option AND ssl_option_list ;

ssl_option:
    CIPHER _english
  | ISSUER _english
  | SUBJECT _english
;

extra_options:
	| | grant_option | WITH resource_option_list ;

grant_option:
	| | WITH GRANT OPTION ;

resource_option_list:
	resource_option | resource_option resource_option_list ;

resource_option: 
    MAX_QUERIES_PER_HOUR _smallint_unsigned
  | MAX_UPDATES_PER_HOUR _smallint_unsigned
  | MAX_CONNECTIONS_PER_HOUR _smallint_unsigned
  | MAX_USER_CONNECTIONS _smallint_unsigned
;

create_drop_table_schema:
	CREATE or_replace DATABASE db_name |
	CREATE DATABASE if_not_exists db_name |
	DROP DATABASE if_exists db_name |
	CREATE or_replace TABLE db_name . table_name (`pk` INT PRIMARY KEY, `col` VARCHAR(8)) |
	CREATE TABLE if_not_exists db_name . table_name (`pk` INT PRIMARY KEY, `col` VARCHAR(8)) |
	DROP TABLE if_exists db_name . table_name ;

db_name:
	_letter ;

tbl_name:
	_letter ;

routine_name:
	_letter ;

col_name:
	_letter ;


