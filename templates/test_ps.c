// gcc -c -I/data/bld/10.3/include/mysql -I/data/bld/10.3/include/mysql/.. test2.c && gcc -o test2 test2.o  -L/data/bld/10.3/lib/ -lmariadb  -ldl -lm -lpthread -lssl -lcrypto


// Up to and including 10.1
// #include <my_global.h>

#include <mysql.h>
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv)
{  
  MYSQL *con = mysql_init(NULL);
  MYSQL_STMT *stmt = mysql_stmt_init(con);

  if (con == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      exit(1);
  }

  if (mysql_real_connect(con, "127.0.0.1", "root", "", 
          "test", 0, NULL, 0) == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_stmt_prepare(stmt,
    "EXPLAIN SELECT * INTO OUTFILE 'load.data' FROM mysql.db", 55)) 
  {
    fprintf(stderr, "%s\n", mysql_error(con));
    mysql_close(con);
    exit(1);
  }

  if (mysql_stmt_execute(stmt))
  {
    fprintf(stderr, " %s\n", mysql_stmt_error(stmt));
    exit(1);
  }

  mysql_close(con);
  exit(0);
}

