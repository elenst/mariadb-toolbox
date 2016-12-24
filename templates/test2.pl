use DBD::mysql;
use Carp;

my $dbh = DBI->connect("dbi:mysql:host=127.0.0.1:port=3307:user=root:database=test", undef, undef, { RaiseError => 1 } );
foreach (1..1) {
	my $sth = $dbh->prepare("select UNIX_TIMESTAMP(my_timestamp_field) AS my_name FROM my_table WHERE my_column=4");
    $sth->execute();
    $sth->fetchrow_arrayref;
}
#	$dbh->do("shutdown");
	print "All done.\n";
sleep 10;

