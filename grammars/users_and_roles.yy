query:
	create_drop_user | 
	create_drop_role | 
	grant_revoke_access | 
	grant_revoke_role | 
	set_role | 
	create_drop_table_schema ;

if_exists:
	| IF EXISTS | IF EXISTS ;

if_not_exists:
	| IF NOT EXISTS | IF NOT EXISTS;

or_replace:
	| OR REPLACE | OR REPLACE;

admin_option:
	| WITH ADMIN OPTION ;

user_name:
	foo | bar | user1 | user2 | user1@localhost | user2@localhost | foo@localhost | bar@localhost | '' | ''@localhost | none | null ;

role_name:
	foo | bar | role1 | role2 | '' | none | null | 'role3@localhost' ;

grantee_name:
	user_name | role_name ;

create_drop_user:
	CREATE or_replace USER user_name |
	CREATE USER if_not_exists user_name |
	DROP USER if_exists user_name ;

create_drop_role:
	CREATE or_replace ROLE role_name |
	CREATE ROLE if_not_exists role_name |
	DROP ROLE if_exists role_name ;

grant_type:
	ALL | SELECT ;

grant_object:
	db_name.* | db_name.table_name ;

db_name:
	db1 | db2 | db3 ;

table_name:
	t1 | t2 | t3 ;

grant_revoke_access:
	GRANT grant_type ON grant_object TO grantee_name |
	REVOKE grant_type ON grant_object FROM grantee_name ;

grant_revoke_role:
	GRANT grantee_name TO grantee_name admin_option ;

default:
	| | DEFAULT ;

role_target:
	| FOR grantee_name ;

set_role:
	SET default ROLE grantee_name |
	SET DEFAULT ROLE grantee_name role_target ;

create_drop_table_schema:
	CREATE or_replace DATABASE db_name |
	CREATE DATABASE if_not_exists db_name |
	DROP DATABASE if_exists db_name |
	CREATE or_replace TABLE db_name . table_name (`pk` INT PRIMARY KEY, `col` VARCHAR(8)) |
	CREATE TABLE if_not_exists db_name . table_name (`pk` INT PRIMARY KEY, `col` VARCHAR(8)) |
	DROP TABLE if_exists db_name . table_name ;

