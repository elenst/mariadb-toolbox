use Getopt::Long;
use strict;

my $opt_remove_connections;
my $opt_preserve_connections;

GetOptions ( 	
			"remove-connections=s"              => \$opt_remove_connections,
			"preserve-connections=s"              => \$opt_preserve_connections,
			);

unless ( $opt_remove_connections or $opt_preserve_connections ) 
{
	print STDERR "Use --remove-connections or --preserve-connections option with a comma-separated list of connection names you want to remove from the test or keep in the test\n";
	exit;
}
if ( $opt_remove_connections and $opt_preserve_connections )
{
	print STDERR "Use only one of --remove-connections or --preserve-connections option with a comma-separated list of connection names you want to remove from the test or keep in the test\n";
	exit;
}
my @c = ();
if ( $opt_remove_connections and $opt_remove_connections =~ /^(\d+)-(\d+)/ )
{
	my ( $first, $last ) = ( $1, $2 );
	for my $i ( $first .. $last )
	{
		push @c, 'con'.$i;
	}
}
else {	
	@c = split /,/, ( $opt_remove_connections || $opt_preserve_connections );
}

my %connections = ();
foreach ( @c ) { $connections{$_} = 1 };

my $ignore;

while (<>) 
{
	if ( /^\s*\-\-(?:connect\s*\(\s*|disconnect\s+|connection\s+)([^\s\,]+)/s ) 
	{
		$ignore = ( $opt_remove_connections and $connections{$1} ) || ( $opt_preserve_connections and not $connections{$1} );
		#print STDERR "COnnection $1 - in hash? $connections{$1}; ignore? $ignore\n";
	}
	print unless $ignore;
}

