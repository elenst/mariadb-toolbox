// gcc -c -I/data/repo/bzr/5.5-noga-hf/include/mysql -I/data/repo/bzr/5.5-noga-hf/include/mysql/.. -Wall -Wunused -Wno-uninitialized -DSAFEMALLOC -g3 -gdwarf-2 -USAFEMALLOC -UFORCE_INIT_OF_VARS -DMYSQL_SERVER_SUFFIX=-valgrind-max  -fPIC -g test.c
// run mysql_config --cflags for correct values and substitute with the real path

// gcc -o test test.o -L/data/repo/bzr/5.5-noga-hf/libmysql -lmysqlclient -lpthread -lz -lm -lrt -ldl
// run mysql_config --libs for correct values and substitute with the real path

#include <my_global.h>
#include <mysql.h>


int main(int argc, char **argv)
{  
  MYSQL *con = mysql_init(NULL);

  if (con == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      exit(1);
  }

  if (mysql_real_connect(con, "localhost", "root", "root_pswd", 
          NULL, 0, NULL, 0) == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }  

  if (mysql_query(con, "CREATE DATABASE testdb")) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  mysql_close(con);
  exit(0);
}

