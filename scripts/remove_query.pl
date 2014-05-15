use Getopt::Long;

my $opt_query;

GetOptions (
	"query=s" => \$opt_query,
);

while (<>)
{
	unless ( /^\s*$opt_query/i ) {
		print;
	}
}

