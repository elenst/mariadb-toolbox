# Include file for using in various table-related tests
# If generic tables are enough

CREATE TABLE t1 (pk INT PRIMARY KEY, a CHAR(8));
CREATE TABLE t2 (b INT);

INSERT INTO t1 VALUES (1,10),(2,20);
INSERT INTO t2 VALUES (NULL);
