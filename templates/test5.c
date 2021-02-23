// gcc -c -I/data/repo/bzr/5.5/include/mysql -I/data/repo/bzr/5.5/include/mysql/.. test2.c && gcc -o test2 test2.o -L/data/repo/bzr/5.5/libmysql -lmysqlclient  && ./test2


#include <my_global.h>
#include <mysql.h>

int main(int argc, char **argv)
{  
  MYSQL *con = mysql_init(NULL);
  MYSQL_STMT *stmt = mysql_stmt_init(con);
  MYSQL_BIND    bind[2];
  unsigned long length[2];
  int           int_data;
  my_bool       is_null[2];
  my_bool       error[2];
  char          str_data[2048];

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

  if (mysql_query(con,
    "DROP TABLE IF EXISTS dbmail_mimeparts"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_query(con,
    "CREATE TABLE dbmail_mimeparts ( "
      "id bigint(20), "
      "data longblob NOT NULL "
    ") ENGINE=InnoDB"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_query(con,
    "INSERT INTO `dbmail_mimeparts` VALUES "
    "(62,REPEAT('b',89)),"
    "(63,REPEAT('c',1251)),"
    "(64,REPEAT('d',1355)),"
    "(69,REPEAT('f',907)),"
    "(72,REPEAT('h',1355))"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_query(con,
    "DROP TABLE IF EXISTS dbmail_partlists"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_query(con,
    "CREATE TABLE dbmail_partlists ("
      "part smallint(6), "
      "part_id bigint(20) "
    ") ENGINE=InnoDB"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_query(con,
    "INSERT INTO dbmail_partlists VALUES "
    "(4,63),(5,64),(9,69),(11,64),(12,72),(15,62)"))
  {
      fprintf(stderr, "%s\n", mysql_error(con));
      mysql_close(con);
      exit(1);
  }

  if (mysql_stmt_prepare(stmt,
    "SELECT l.part,p.data "
      "from dbmail_mimeparts p "
      "join dbmail_partlists l on p.id=l.part_id "
      "order by l.part", 102)) 
  {
    fprintf(stderr, "%s\n", mysql_error(con));
    mysql_close(con);
    exit(1);
  }

  unsigned long cursor = CURSOR_TYPE_READ_ONLY;
  mysql_stmt_attr_set(stmt, STMT_ATTR_CURSOR_TYPE, &cursor);

  if (mysql_stmt_execute(stmt))
  {
    fprintf(stderr, " %s\n", mysql_stmt_error(stmt));
    exit(1);
  }

    query.prepare("SELECT recordid, category, "
                  "       (category = :CAT1) AS catmatch, "
                  "       (category = :CATTYPE1) AS typematch "
                  "FROM record "
                  "WHERE type = :TEMPLATE AND "
                  "      (category = :CAT2 OR category = :CATTYPE2 "
                  "       OR category = 'Default') "
                  "ORDER BY catmatch DESC, typematch DESC"
                  );
    query.bindValue(":TEMPLATE", kTemplateRecord);
    query.bindValue(":CAT1", category);
    query.bindValue(":CAT2", category);
    query.bindValue(":CATTYPE1", categoryType);
    query.bindValue(":CATTYPE2", categoryType);


  bind[1].buffer_type= MYSQL_TYPE_STRING;
  bind[1].buffer= (char *)str_data;
  bind[1].buffer_length= 8;
  bind[1].is_null= &is_null[1];
  bind[1].length= &length[1];
  bind[1].error= &error[1];

  if (mysql_stmt_bind_result(stmt, bind))
  {
    fprintf(stderr, " %s\n", mysql_stmt_error(stmt));
    exit(1);
  }

  while (!mysql_stmt_fetch(stmt))
  {
    fprintf(stdout, " part: %d\n", int_data);
    if (mysql_stmt_bind_result(stmt, bind))
    {
      fprintf(stderr, " %s\n", mysql_stmt_error(stmt));
      exit(1);
    }
  }

  mysql_close(con);
  exit(0);
}

