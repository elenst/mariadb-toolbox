// gcc -c -I/data/bld/10.1/include/mysql -I/data/bld/10.1/include/mysql/private -I/data/bld/10.1/include/mysql/.. test.c 
// gcc -o test test.o -L/data/bld/10.1/lib  -lmysqlclient -lpthread -lz -lm -ldl -lssl -lcrypto

#include <my_global.h>
#include <mysql.h>
#include <sql_common.h>


int main(int argc, char **argv)
{  
  MYSQL *con = mysql_init(NULL);

  if (con == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      exit(1);
  }

  mysql_options(con, MYSQL_READ_DEFAULT_FILE, "/data/tmp/mdev10246.cnf");
  mysql_options(con,MYSQL_READ_DEFAULT_GROUP,"mdev10246");

  if (mysql_real_connect(con, NULL, NULL, NULL, 
          NULL, 0, NULL, 0) == NULL) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }  

  const char* query= "SHOW STATUS LIKE 'ssl_cipher%'";

  if (mysql_query(con, query)) 
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  MYSQL_RES* result;
  
  if((result= mysql_store_result(con)) == NULL)
  {
      fprintf(stderr,"No result\n");
      exit(1);
  }

  MYSQL_ROW row;
  unsigned int i;
  unsigned int row_num= 0;
  unsigned int num_fields= mysql_num_fields(result);
  MYSQL_FIELD *fields= mysql_fetch_fields(result);
  
    while ((row= mysql_fetch_row(result)))
    {
      unsigned long *lengths= mysql_fetch_lengths(result);
      row_num++;

      fprintf(stderr, "---- %d. ----\n", row_num);
      for(i= 0; i < num_fields; i++)
      {
        fprintf(stderr, "%s\t%.*s\n",
                fields[i].name,
                (int)lengths[i], row[i] ? row[i] : "NULL");
      }
    }
    for (i= 0; i < strlen(query)+8; i++)
      fprintf(stderr, "=");
    fprintf(stderr, "\n\n");

  mysql_free_result(result);

  mysql_close(con);
  exit(0);
}

