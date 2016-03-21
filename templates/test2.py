import MySQLdb

connArgs={"host": "127.0.0.1", "user": "root", "db": "test"}
conn = MySQLdb.connect(**connArgs)
conn2 = MySQLdb.connect(**connArgs)
conn.autocommit = True
conn2.autocommit = True
cursor = conn.cursor(MySQLdb.cursors.DictCursor)
cursor2 = conn2.cursor(MySQLdb.cursors.DictCursor)
cursor.execute("create table t1 (i int) engine=InnoDB")
cursor.execute("insert into t1 values (1)")
cursor.execute("select * from t1")
cursor2.execute("select * from t1")
conn.commit()
cursor2.execute("select * from t1")

