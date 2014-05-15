# THe script eliminates mismatches between MariaDB and MySQL (5.6) encountered 
# due to the different behavior on comparing a temporal field to a string or a number,
# e.g. col_datetime_key < 'abc' 

LINE:
while (<>) {
	next LINE if ( /\`?col_(?:date|time|datetime)_(?:no)?key\`?\s*(?:\>|\<|=|==|\>=|\<=|\!=|\<\>)\s*(?:\'[A-Za-z]+\'|\d+)/ );
	my $line = $_;
	if ( /HAVING(.*)/ ) {
		my $having_clause = $1;
		$having_clause =~ s/ORDER\s+BY.*// ;

		my %date_fields = ();
		my $l = $line;
		while ( $l =~ s/\`?col_(?:date|time|datetime)_(?:no)?key\`?\s+AS\s+field(\d+)// ) {
			$date_fields{'field'.$1} = 1;
		}
		foreach my $k (keys %date_fields) {
			if ( $having_clause =~ /$k\s*(?:\>|\<|=|==|\>=|\<=|\!=|\<\>)\s*(?:\'[A-Za-z]+\'|\d+)/ ) {
				next LINE;
			}
		}
	}
	print $line;
}
	
