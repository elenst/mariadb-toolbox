#
# NOT NULL attribute in columns
#
# Usage:
# let $col_definition = <column type (and possibly more options)>;
# let $col_default = <default non-null value for a column>;
# --source col_not_null.inc
#
# We will add NOT NULL at the end of $col;
#
# Also, if $col_default is defined, 
# we will create a table with 2 columns 
# (one with DEFAULT $col_default, and one without any default), 
# and will also attempt to add a column with DEFAULT NULL.
#

--disable_query_log
let $db = `SELECT UUID_SHORT()`;
eval CREATE DATABASE `$db`;
eval USE `$db`;
--enable_query_log
        

--disable_warnings
# DROP TABLE IF EXISTS t1;
--enable_warnings

--let $create_definition = c $col_definition NOT NULL
--source create_table.inc
if ($mysql_errname)
{
  --source unexpected_result.inc
}
if (!$mysql_errname)
{
  SHOW COLUMNS IN t1;

  --let $error_codes = ER_BAD_NULL_ERROR
  INSERT INTO t1 (c) VALUES (NULL);
  --source check_errors.inc

  # DROP TABLE t1;
}

--disable_query_log
let $db = `SELECT UUID_SHORT()`;
eval CREATE DATABASE `$db`;
eval USE `$db`;
--enable_query_log

if ($col_default != '')
{
  let $create_definition =
    c $col_definition NOT NULL,
    c2 $col_definition NOT NULL DEFAULT $col_default
  ;
  --let $table_name = t1
  --source create_table.inc
  if ($mysql_errname)
  {
    --source unexpected_result.inc
  }
  if (!$mysql_errname)
  {
    SHOW COLUMNS IN t1;

    --let $table_name = t1
    --let $error_codes = ER_INVALID_DEFAULT
    --let $alter_definition = ADD COLUMN err $col_definition NOT NULL DEFAULT NULL
    --source alter_table.inc
    if ($mysql_errname != ER_INVALID_DEFAULT)
    {
      --let $functionality = ALTER or DEFAULT
      --source unexpected_result.inc
    }

    --let $error_codes = ER_BAD_NULL_ERROR
    INSERT INTO t1 (c) VALUES (NULL);
    --source check_errors.inc
    if ($mysql_errname != ER_BAD_NULL_ERROR)
    {
      --let $functionality = NOT NULL columns
     --source unexpected_result.inc
    }

    # HEX should be universal for all column types
    SELECT HEX(c), HEX(c2) FROM t1;

    --let $error_codes = ER_BAD_NULL_ERROR
    INSERT INTO t1 (c2) VALUES (NULL);
    --source check_errors.inc

    --eval INSERT INTO t1 (c) VALUES ($col_default)
    if ($mysql_errname)
    {
      --let $functionality = DEFAULT
      --source unexpected_result.inc
    }
    SELECT COUNT(c), COUNT(c2) FROM t1;

    # DROP TABLE t1;
  }
}

# We don't want to preserve it
let $col_default = ;

