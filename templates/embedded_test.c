// gcc -c -I/data/releases/mariadb-5.5.32-linux-x86_64/include/mysql -I/data/releases/mariadb-5.5.32-linux-x86_64/include/mysql/..  -g -static-libgcc -fno-omit-frame-pointer -fno-strict-aliasing  -DMY_PTHREAD_FASTMUTEX=1 embedded_test.c  
// gcc -o embedded_test embedded_test.o -L/data/releases/mariadb-5.5.32-linux-x86_64/lib -lmysqld -lpthread -lz -lm -lrt -ldl

#include <mysql.h>
#include <stdlib.h>
#include <my_global.h>

static char *server_args[] = {
  "this_program",       /* this string is not used */
  "--datadir=/home/elenst/bzr/5.5/data",
  "--key_buffer_size=32M",
	"--lc-messages-dir=/home/elenst/bzr/5.5/sql/share",
	"--skip-innodb",
	"--default-storage-engine=MyISAM"
};
static char *server_groups[] = {
  "embedded",
  "server",
  "this_program_SERVER",
  (char *)NULL
};

int main(void) {
	int res = mysql_library_init(sizeof(server_args) / sizeof(char *),
                        server_args, server_groups);
  if (res) {
    fprintf(stderr, "could not initialize MySQL library, error %i\n", res);
    exit(res);
  }

  /* Use any MySQL API functions here */

  mysql_library_end();

  return EXIT_SUCCESS;
}

