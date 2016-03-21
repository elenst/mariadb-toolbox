// gcc -c -I/data/releases/mariadb-5.5.32-linux-x86_64/include/mysql -I/data/releases/mariadb-5.5.32-linux-x86_64/include/mysql/..  -g -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing  -DMY_PTHREAD_FASTMUTEX=1 embedded_test.c  
// gcc -o embedded_test embedded_test.o -L/data/releases/mariadb-5.5.32-linux-x86_64/lib -lmysqld -lpthread -lz -lm -lrt -ldl


// Link statically:
// /usr/bin/c++ -I/data/releases/mariadb-5.5.35-linux-x86_64/include/mysql -I/data/releases/mariadb-5.5.35-linux-x86_64/include/mysql/..  -Wall  -fPIC -Wno-unused-parameter -fno-implicit-templates -fno-exceptions -fno-rtti -g -DENABLED_DEBUG_SYNC -DSAFE_MUTEX -DSAFEMALLOC -DUSE_MYSYS_NEW -Wall -Wextra -Wunused -Wwrite-strings -Wno-strict-aliasing -Wno-missing-field-initializers -Wno-unused-parameter -Woverloaded-virtual    -Wl,--export-dynamic embedded_test.o  -o embedded_test  -lpthread /data/releases/mariadb-5.5.35-linux-x86_64/lib/libmysqld.a -lpthread -lz -lm -lrt -lcrypt -ldl -laio

// gcc -c -I/data/releases/mariadb-10.0.18-linux-x86_64/include/mysql -I/data/releases/mariadb-10.0.18-linux-x86_64/include/mysql/..  -g -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing  -DMY_PTHREAD_FASTMUTEX=1 embedded_test.c  
// /usr/bin/c++ -I/data/releases/mariadb-10.0.18-linux-x86_64/include/mysql -I/data/releases/mariadb-10.0.18-linux-x86_64/include/mysql/..  -Wall  -fPIC -Wno-unused-parameter -fno-implicit-templates -fno-exceptions -fno-rtti -g -DENABLED_DEBUG_SYNC -DSAFE_MUTEX -DSAFEMALLOC -DUSE_MYSYS_NEW -Wall -Wextra -Wunused -Wwrite-strings -Wno-strict-aliasing -Wno-missing-field-initializers -Wno-unused-parameter -Woverloaded-virtual    -Wl,--export-dynamic embedded_test.o  -o embedded_test  -lpthread /data/releases/mariadb-10.0.18-linux-x86_64/lib/libmysqld.a -lpthread -lz -lm -lrt -lcrypt -ldl -laio

#include <mysql.h>
#include <stdlib.h>
#include <my_global.h>

static char *server_args[] = {
  "this_program",       /* this string is not used */
  "--datadir=/home/elenst/git/10.0/data",
  "--core-file",
	"--lc-messages-dir=/home/elenst/git/10.0/sql/share"
};
static char *server_groups[] = {
  "embedded",
  "server",
  "this_program_SERVER",
  (char *)NULL
};

int main(void) {
   fprintf(stderr, "We are here\n");
	int res = mysql_server_init(sizeof(server_args) / sizeof(char *),
                        server_args, server_groups);
  if (res) {
    fprintf(stderr, "could not initialize MySQL library, error %i\n", res);
    exit(res);
  }

MYSQL *mysql;
MYSQL_RES *results;
MYSQL_ROW record;

   mysql = mysql_init(NULL);
   mysql_real_connect(mysql, NULL,NULL,NULL, "test", 0,NULL,0);

//   mysql_query(mysql, "CREATE TABLE test.t1 (i INT)");
   mysql_query(mysql, "CREATE TRIGGER test.trg2 AFTER DELETE ON test.t1 FOR EACH ROW SET @a=1");

   mysql_query(mysql, "SELECT @@version");


  /* Use any MySQL API functions here */

	results = mysql_store_result(mysql);

   while((record = mysql_fetch_row(results))) {
      printf("%s - %s \n", record[0], record[1]);
   }

   mysql_free_result(results);
   mysql_close(mysql);

  mysql_server_end();

  return EXIT_SUCCESS;
}

