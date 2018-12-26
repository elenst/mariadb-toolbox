use DBI;
use strict;

my $dbh = DBI->connect("dbi:mysql:host=127.0.0.1:port=3306:user=root:database=test;mysql_server_prepare=1");

unless (defined $dbh) {
  print "Couldn't connect: ".$DBI::errstr."\n";
  exit 1;
}

print "All good\n" if $dbh->do("EXPLAIN SELECT * INTO OUTFILE 'load.data' FROM mysql.db");

$dbh->disconnect();
