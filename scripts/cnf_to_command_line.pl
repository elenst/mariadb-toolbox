use strict;

my $cmd = '';

while (<>) {
	if (/^\s*\[/) { next }; # ignore sections for now
	if (/^\s*\#/) { next }; # comment
	if (/^\s*(\S+)\s*=?\s*(\'[^\']*\'|\"[^\"]*\"|[^\#\s]*)/) {
		my ( $name, $val ) = ( $1, $2 );
		$cmd .= " --mysqld=--$name";
		if ( defined $val and $val =~ /\S/ ) {
			if ( $val !~ /^[\'\"]/ ) { $val = "'".$val."'" };
			$cmd.= "=$val";
		}
	}
}

print "$cmd\n";

