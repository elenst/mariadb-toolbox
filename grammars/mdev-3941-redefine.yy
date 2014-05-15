# MDEV-3941: CREATE TABLE xxx IF NOT EXISTS should not block if table exists
# TODO-352:  Run stress tests for MDEV-3941 (non-waiting CREATE TABLE)

thread1:
	mdev_create_table;

thread2:
	mdev_create_table;

mdev_create_table:
	CREATE TABLE mdev_if_not_exists _table ( `i` INT ) | 
	CREATE TABLE mdev_if_not_exists _table LIKE _table |
	CREATE TABLE mdev_if_not_exists _table AS SELECT * FROM _table | 
	CREATE TABLE mdev_if_not_exists _tmptable[invariant] ( `i` INT ) ; DROP TABLE _tmptable[invariant] |
	CREATE TABLE mdev_if_not_exists _tmptable[invariant] LIKE _table ; DROP TABLE _tmptable[invariant] |
	CREATE TABLE mdev_if_not_exists _tmptable[invariant] AS SELECT * FROM _table ; DROP TABLE _tmptable[invariant] |
	CREATE TEMPORARY TABLE _table ( `i` INT ) ; DROP TEMPORARY TABLE _table ;

mdev_if_not_exists:
	| IF NOT EXISTS ;

