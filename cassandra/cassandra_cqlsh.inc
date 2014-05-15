#
# A template to include (or copy-paste) into MTR test cases for Cassandra.
# create columnfamily needs to be modified to reflect the desired structure.
# Keyspace to use in table creation is called 'bug'
#

--source include/have_cassandra.inc

--echo # Inside cassandra_cqlsh.inc

SET GLOBAL cassandra_default_thrift_host = '127.0.0.1';

--remove_files_wildcard $MYSQLTEST_VARDIR cassandra_test_cleanup.cql
--write_file $MYSQLTEST_VARDIR/cassandra_test_cleanup.cql
drop keyspace bug;
EOF
--error 0,1,2
--system cqlsh -3 -f $MYSQLTEST_VARDIR/cassandra_test_cleanup.cql

--remove_files_wildcard $MYSQLTEST_VARDIR cassandra_test_init.cql
--write_file $MYSQLTEST_VARDIR/cassandra_test_init.cql

CREATE KEYSPACE bug
  WITH strategy_class = 'org.apache.cassandra.locator.SimpleStrategy'
  AND strategy_options:replication_factor='1';

USE bug;
create columnfamily cf1 ( pk int primary key, col_varbinary_1024 blob, col_varchar_256 ascii, col_varbinary_32 varint, col_int int, col_bigint bigint, col_tinyint bigint, col_smallint bigint, col_timestamp timestamp, col_timestamp_6 timestamp, col_bool boolean, col_float float, col_double double );
EOF

--system cqlsh -3 -f $MYSQLTEST_VARDIR/cassandra_test_init.cql


