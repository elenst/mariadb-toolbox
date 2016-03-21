use DBD::mysql;
use Carp;

my $pid = fork();

if ($pid) {
	sleep 1;
	my $dbh = DBI->connect("dbi:mysql:host=127.0.0.1:port=3306:user=root:database=test", undef, undef, { RaiseError => 1 } );
	foreach (1..100) {
		$dbh->do("CREATE OR REPLACE VIEW v AS SELECT 1");
	}
	$dbh->do("shutdown");
	print "All done.\n";
}
elsif ($pid == 0) {
	my $dbh = DBI->connect("dbi:mysql:host=127.0.0.1:port=3306:user=root:database=test", undef, undef, { RaiseError => 1 } );
	sleep 2;
	croak "$$ Aborting now";
}

else {
	die "Could not fork";
}

