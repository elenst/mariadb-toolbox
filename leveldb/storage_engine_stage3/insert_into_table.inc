##################################
#
# This include file will be used for all INSERT INTO TABLE statements in the suite. 
# If you need to add additional steps or change the logic, copy the file 
# to storage/<engine>/mysql-test/storage_engine/ folder and modify it there.
#
##################
#
# Parameters: 
#
# --let $table_name = <table name>                            # optional, default t1
# --let $insert_values = <list of values, comma-separated>    # optional, default empty
# --let $insert_columns = <list of columns, comma-separated>  # optional, default empty
# --let $insert_options = <IGNORE etc>                        # optional, default empty
# --let $insert_select = <SELECT statement>                   # optional, default empty
# --let $error_codes = <expected error codes, as in --error>  # optional, default 0
# --let $disable_query_log = [0|1]                            # optional, default 0 (1 disables logging of CREATE)
#
# Usage examples:
#
# --source insert_table.inc # INSERT INTO t1 VALUES ()
#
# --let $table_name = t2
# --let $insert_values = 'x',1
# --let $insert_columns = a,b
# --source insert_into_table.inc # INSERT INTO t1 (a,b) VALUES ('x',1)
#


--let $insert_statement = INSERT

if ($insert_options)
{
  --let $insert_statement = $insert_statement $insert_options
}

if (!$table_name)
{
  --let $table_name = t1
}

--let $insert_statement = $insert_statement INTO $table_name

if ($insert_columns)
{
  --let $insert_statement = $insert_statement ($insert_columns)
}

if ($insert_select)
{
  --let $insert_statement = $insert_statement $insert_select
}
if (!$insert_select)
{
  --let $insert_values = ($insert_values)
  --let $insert_statement = $insert_statement VALUES $insert_values
}

#####################
# Up to this point you can add more logic
# (e.g. add and populate custom columns, etc. ).
# Surround it by --disable_query_log/--enable_query_log
# if you don't want it to appear in the result output.
# Now we will run the statement itself. 
#####################

if ($disable_query_log)
{
  --disable_query_log
}
eval $insert_statement;
--source strict_check_errors.inc

# Make sure you don't add any statements between the main INSERT (above)
# and saving mysql_errno and mysql_errname (below)
# They are saved in case you want to add more logic after the main INSERT,
# because we need the result code of the table creation.
# Also, do not change $insert_statement after it is executed!

--let $my_errno = $mysql_errno
--let $my_errname = $mysql_errname


if ($disable_query_log)
{
  --enable_query_log
}

#####################
# Here you can add logic needed AFTER the main INSERT.
# Surround it by --disable_query_log/--enable_query_log
# if you don't want it to appear in the result output.
#####################


# Unset the parameters, we don't want them to be accidentally reused later
--let $table_name = t1
--let $insert_values =
--let $insert_columns =
--let $insert_options =
--let $insert_select = 0
--let $error_codes =
--let $disable_query_log = 0

# Restore the error codes of the main statement
--let $mysql_errno = $my_errno
--let $mysql_errname = $my_errname
# Make sure you don't add any SQL statements after restoring 
# mysql_errno and mysql_errname (above)

