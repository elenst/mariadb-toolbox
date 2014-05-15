#! /usr/bin/python

import MySQLdb as mdb
import datetime

now = datetime.datetime.now()

conn = mdb.connect(host="127.0.0.1", user="root", passwd="", db="test")
cursor = conn.cursor()

tablename = "t1"
stmt = "DROP TABLE IF EXISTS %s" % tablename
# 	print stmt
cursor.execute(stmt)

stmt = "CREATE TABLE IF NOT EXISTS %s(year INT(4) PRIMARY KEY AUTO_INCREMENT, last_modified DATETIME DEFAULT '0000-00-00 00:00:00', " % tablename
for i in range(10):
	if i == 9:
		stmt += "d%03d INT(12) DEFAULT 0)" %(i+1)
	else:
		stmt += "d%03d INT(12) DEFAULT 0, " %(i+1)

# print stmt
cursor.execute(stmt) 

# populate table t1 with zeros
for i in range(1):
	fields = "year,"
	values = "%s," % ( int(now.year) + i )
	for i in range(10):
		if i == 9:
			fields += "d%03d" % (i+1)
			values += "0"
		else:
			fields += "d%03d," % (i+1)
			values += "0,"

	stmt = "insert into %s(%s) values(%s)" % (tablename,fields,values)
#  	print stmt
	cursor.execute(stmt) 

# retrieve and print data from t1
stmt = "SELECT * FROM %s" % tablename 
cursor.execute(stmt)
table = cursor.fetchall()

print table

# truncate and then repopulate t1 with ones
stmt = "TRUNCATE TABLE %s" % tablename
# 	print stmt
cursor.execute(stmt) 

for i in range(1):
	fields = "year,"
	values = "%s," % ( int(now.year) + i )
	for i in range(10):
		if i == 9:
			fields += "d%03d" % (i+1)
			values += "1"
		else:
			fields += "d%03d," % (i+1)
			values += "1,"

	stmt = "insert into %s(%s) values(%s)" % (tablename,fields,values)
#  	print stmt
	cursor.execute(stmt) 

# retrieve and print data from t1
stmt = "SELECT * FROM %s" % tablename
cursor.execute(stmt)
table = cursor.fetchall()

print table

#stmt = "COMMIT"
#cursor.execute(stmt)


conn.close()

# reconnect, retrieve, and print t1
conn = mdb.connect(host="127.0.0.1", user="root", passwd="", db="test")
cursor = conn.cursor()

stmt = "SELECT * FROM %s" % tablename
cursor.execute(stmt)
table = cursor.fetchall()

conn.close()

print table


