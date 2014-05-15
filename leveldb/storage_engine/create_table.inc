##################################
#
# This include file will be used for all CREATE TABLE statements in the suite. 
# If you need to add additional steps or change the logic, copy the file 
# to storage/<engine>/mysql-test/storage_engine/ folder and modify it there.
#
##################
#
# Parameters: 
#
# --let $create_definition = <column names, types, indexes)   # optional, default a $int_col, b $char_col (based on defaults)
# --let $table_name = <table name>                            # optional, default t1
# --let $table_options = <table options>                      # optional, default based on define_engine.inc
# --let $partition_options = <partitioning definition>        # optional, default none
# --let $as_select = <SELECT statement>                       # optional, default empty
# --let $error_codes = <expected error codes, as in --error>  # optional, default 0
# --let $if_not_exists = [0|1]                                # optional, default 0 (1 adds IF NOT EXISTS clause)
# --let $default_engine = [0|1]                               # optional, default 0 (with 1 will rely on default engine, no ENGINE=)
# --let $temporary = [0|1]                                    # optional, default 0 (1 adds TEMPORARY)
# --let $disable_query_log = [0|1]                            # optional, default 0 (1 disables logging of CREATE)
#
# Usage examples:
#
# --source create_table.inc -- creates a default table
#
# --let $create_definition = a INT NOT NULL, b CHAR(1) PRIMARY KEY, INDEX(a)
# --let $table_options = AUTO_INCREMENT = 100
# --let $partition_options = PARTITION BY HASH(a) PARTITIONS 2
# --let $as_select = SELECT 1, 'a'
# --source create_table.inc
#
# Additionally, a test can define $extra_tbl_options. The difference with $table_options
# is that its value is persistent and will be used until it is unset explicitly, or
# until the test ends. The purpose of it is to allow one test to call another test,
# when the called test does not know about specific options the calling test might require,
# and thus cannot set them on per-create basis.

--let $create_statement = CREATE

if ($temporary)
{
  --let $create_statement = $create_statement TEMPORARY
}

--let $create_statement = $create_statement TABLE

if ($if_not_exists)
{
  --let $create_statement = $create_statement IF NOT EXISTS
}

if (!$table_name)
{
  --let $table_name = t1
}

--let $create_statement = $create_statement $table_name

if (!$create_definition)
{
  # If $create_definition is not defined, and AS SELECT is requested,
  # we should not set $create_definition to the default value,
  # because it might be inconsistent with the SELECT.
  if (!$as_select)
  {
    --let $create_definition = a $int_col, b $char_col
  }
}

if ($create_definition)
{
  --let $create_statement = $create_statement ($create_definition)
}

# If $default_engine is set, we will rely on the default storage engine

if (!$default_engine)
{
  --let $create_statement = $create_statement ENGINE=MyISAM
}

# Default table options from define_engine.inc
--let $create_statement = $create_statement $default_tbl_opts

# The calling script could request additional table options
if ($table_options)
{
  --let $create_statement = $create_statement $table_options
}

# The difference between $extra_tbl_opts and $table_options
# is that its $extra_tbl_opts is persistent -- it will not be unset at the end of this file,
# and will be used until it is unset explicitly by the calling test,
# or until the test ends. The purpose of it is to allow one test to call another test,
# when the called test does not know about specific options the calling test might require,
# and thus cannot set them on per-create basis.

if ($extra_tbl_opts)
{
  --let $create_statement = $create_statement $extra_tbl_opts
}

if ($as_select)
{
  --let $create_statement = $create_statement AS $as_select
}

if ($partition_options)
{
  --let $create_statement = $create_statement $partition_options
}

# We now have the complete CREATE statement in $create_statement.
# If your CREATE statement should be composed differently, 
# modify the logic above.

#####################
# Here you can add logic needed BEFORE the main table creation
# (e.g. the table needs a base table, a reference table, etc.).
# Surround it by --disable_query_log/--enable_query_log
# if you don't want it to appear in the result output.
#####################

if ($disable_query_log)
{
  --disable_query_log
}

--disable_query_log

--source obfuscate.inc

eval $create_statement;

if (!$mysql_errno)
{
# Drop all non-unique keys, we don't want them
let $key = query_get_value(SHOW INDEXES IN $table_name WHERE `Non_unique` = 1 OR `Null`='YES', Key_name, 1);
while ($key != 'No such row')
{
  eval ALTER TABLE `$table_name` DROP KEY `$key`;
  let $key = query_get_value(SHOW INDEXES IN $table_name WHERE `Non_unique` = 1 OR `Null`='YES', Key_name, 1);
}

# Drop all unique keys if there is a PK; otherwise, left one

while (`SELECT COUNT(*) > 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA=DATABASE()`)
{
  let $key = query_get_value(SHOW INDEXES IN $table_name WHERE `Key_name`!='PRIMARY', Key_name, 1);
  eval ALTER TABLE `$table_name` DROP KEY `$key`;
}

# If there is no key left, create a PK; preferably, try a non-blob column,
# but if there is none, try blob
if (!`SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA=DATABASE()`)
{
  let $col_name = `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' 
  AND TABLE_SCHEMA=DATABASE() 
  AND ( CHARACTER_MAXIMUM_LENGTH > 0 OR NUMERIC_PRECISION > 0 OR DATETIME_PRECISION IS NOT NULL OR DATA_TYPE IN ( 'date', 'year' ) ) 
  ORDER BY NUMERIC_PRECISION DESC, CHARACTER_MAXIMUM_LENGTH DESC, COLUMN_NAME DESC LIMIT 1`;
#  AND DATA_TYPE NOT IN ('text','blob')
  let $ind_size = `SELECT IFNULL(IF(CHARACTER_MAXIMUM_LENGTH>255,255,CHARACTER_MAXIMUM_LENGTH),'') FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND COLUMN_NAME='$col_name' AND TABLE_SCHEMA=DATABASE() AND (COLUMN_TYPE LIKE '%char%' OR COLUMN_TYPE LIKE '%binary%')`;
  if ($ind_size)
  {
    let $ind_size = ($ind_size);
  }
  eval ALTER TABLE `$table_name` ADD PRIMARY KEY (`$col_name`$ind_size);
}

let $table_def = query_get_value(SHOW CREATE TABLE $table_name, Create Table, 1);
let $table_def = `SELECT REPLACE(REPLACE("$table_def",'\0','\\\\\0'),'MyISAM','LevelDB')`;

# Rename MyISAM table into a temporary name,
# create a LevelDB table, populate it (in case it was created AS SELECT),
# then drop the MyISAM table

eval RENAME TABLE `$table_name` TO `tmp_$table_name`;

if (!$disable_query_log)
{
  --enable_query_log
}
eval $table_def;

--disable_query_log
eval INSERT INTO $table_name SELECT * FROM tmp_$table_name;
eval DROP TABLE tmp_$table_name;

if (!$disable_query_log)
{
  --enable_query_log
}
}

--source strict_check_errors.inc

# Make sure you don't add any statements between the main CREATE (above)
# and saving mysql_errno and mysql_errname (below)
# They are saved in case you want to add more logic after the main CREATE,
# because we need the result code of the table creation.
# Also, do not change $create_statement after it is executed!

--let $my_errno = $mysql_errno
--let $my_errname = $mysql_errname


if ($disable_query_log)
{
  --enable_query_log
}

#####################
# Here you can add logic needed AFTER the main table creation,
# e.g. triggers creation.
# Surround it by --disable_query_log/--enable_query_log
# if you don't want it to appear in the result output.


#####################


# Unset the parameters, we don't want them to be accidentally reused later
--let $create_definition =
--let $table_name = t1
--let $table_options = 
--let $partition_options = 
--let $as_select = 0
--let $error_codes =
--let $if_not_exists = 0
--let $default_engine = 0
--let $temporary = 0
--let $disable_query_log = 0

# Restore the error codes of the main statement
--let $mysql_errno = $my_errno
--let $mysql_errname = $my_errname
# Make sure you don't add any SQL statements after restoring 
# mysql_errno and mysql_errname (above)

