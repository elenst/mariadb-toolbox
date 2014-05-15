#
# CQL to run before RQG cassandra tests.
# Columnfamily definition might need to be modified.

drop keyspace rqg;
CREATE KEYSPACE rqg
  WITH strategy_class = 'org.apache.cassandra.locator.SimpleStrategy'
  AND strategy_options:replication_factor='1';
use rqg;

drop columnfamily cf1;
create columnfamily cf1 ( pk int primary key, col_varbinary_1024 blob, col_varchar_256 ascii, col_varbinary_32 varint, col_int int, col_bigint bigint, col_tinyint bigint, col_smallint bigint, col_timestamp timestamp, col_timestamp_6 timestamp, col_bool boolean, col_float float, col_double double );

