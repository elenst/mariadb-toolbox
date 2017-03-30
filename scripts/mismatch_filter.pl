# The script will return 1 if there are real mismatches, otherwise the exit code is 0.
#
# The script is supposed to be used as
#   mismpatch_filter.pl trial*log 1>mismatches 2>/dev/null or alike.
# But on Windows shell won't do the expansion, so the script has to take care of the wildcard.

use Getopt::Long;
use strict;

$| = 1;
my $lineno = 0;
my $mismatch;
my $count = 0;
my $debug = 0;
my $report_binary_diffs = 1;

GetOptions (
    "debug"  => \$debug,
    "binary_diffs!"      => \$report_binary_diffs,
    "binary-diffs!"      => \$report_binary_diffs,
);


my @names = ();
foreach (@ARGV) {
   my @expansion = glob($_);
   @names = ( @names, @expansion );
}
@ARGV = @names;

#----------------

sub debug {
   if ($debug) { print STDERR @_ }
}

my $exit_code = 0;

LINE:
while (<>)
{
	$lineno = $.;
	close (ARGV) if (eof);
	# This is for comparison test. $1 is the query, $2 is length/content mismatch specification
#	next unless (
#		/---------- RESULT COMPARISON ISSUE START ----------/
#		or
#		/---------- TRANSFORM ISSUE ----------/
#	);

	next unless (
			/Query:\s+(.*)\s+failed:\s+result\s+(length|content)\s+mismatch\s+between\s+servers/i
			or
			/Original query:\s+(.*)\s+failed\s+transformation\s+with\s+Transformer\s+\w+\;\s+RQG\s+Status:\s+STATUS_(CONTENT|LENGTH)_MISMATCH/i
	);
	$count++;
	my $init_query = $1;
	$mismatch = lc($2);
    my $diff = '';
    my $line;
    while ($line = <> and $line !~ /(?:RESULT COMPARISON ISSUE END|END OF TRANSFORM ISSUE)/) {
        $diff .= $line;
    }

	my $query = make_neater( $init_query );
	debug "########### mismatch $count ###########\n$ARGV, line $lineno, initial query (mismatch: $mismatch):\n$query\n";

	if ( $query =~ s/UNION/\) \(/i )
	{
		print "$ARGV, line $lineno, mismatch " . $count . " is with UNION, check!\n\n";
	}

	my @subqueries = extract_subqueries( $query, 1 );

	foreach my $sq ( @subqueries )
	{
		debug "Subquery:\n", $sq, "\n";
		unless ( legitimate($sq) ) {
			debug "Query is not legit\n\n";
			next LINE;
		}
	}

	if ($report_binary_diffs or $diff !~ /Binary files \S+ and \S+ differ/) {
		print "#------------------------------\n$ARGV, line $lineno, found $mismatch mismatch between servers:\n";
		print $init_query, "\n\n";
	#	print "The same query but cleaned up:\n";
	#	print $query, "\n\n";
		print "$diff\n#------------------------------\n";
	   $exit_code = 1;
	}
}

exit($exit_code);

sub make_neater
{
	my $query = shift;
	$query =~ s/  / /g;
	$query =~ s/ \./\./g;
	$query =~ s/\. /\./g;
	$query =~ s/\`//g;
	$query =~ s/^\ //;
	$query =~ s/\ $//;
	$query =~ s/ ,/,/g;
#	$query =~ s/, /,/g;
	$query =~ s/(\S)([\(\)])/$1 $2/g;
	$query =~ s/\/\*.*?\*\///g;
	$query =~ s/\)/ \) /g;
	$query =~ s/\(/ \( /g;
	while ( $query =~ s/  / /g ) {};

	return $query;
}

sub legitimate
{
	my $query = shift;
	if ( $query =~ /^\s*$/ ) { return 1 };
	# Only SELECTs are interesting for matching
	if ( $query !~ /^\s*SELECT/i ) { debug "Query is not SELECT, not legit\n"; return 0 };

	my %field_names;
	my %field_aliases;
	my %alias_names;
	my $aggregate = 0;
	my $non_aggregate = 0;
	if ( $query =~ /^\s*SELECT\W+(?:\WALL|DISTINCT|DISTINCTROW|HIGH_PRIORITY|STRAIGHT_JOIN|SQL_SMALL_REESULT|SQL_BIG_RESULT|SQL_BUFFER_RESULT|SQL_CACHE|SQL_NO_CACHE|SQL_CALC_FOUND_ROWS\W+)?(.*?)(?:(?:FROM|WHERE).*)?$/i )
	{
		my $fields = $1;
		$fields =~ s/^\s*\((.*?)\)\s*$//g;
		debug "Fields: $fields\n";
		my $num = 0;
		my @fields = split /,/, $fields;
		foreach my $f ( @fields )
		{
			$num++;
			$f =~ /^\s*(.*?)\s*(?:\s*AS\s+(\w+))?\s*$/i;
			debug "Checking field $1\n";
			if ( $2 ) {
				$alias_names{$2} = 1;
				$field_aliases{$1} = $2;
			}
			if ( $1 =~ /^\s*(?:MAX|MIN|SUM|COUNT|AVG|GROUP_CONCAT|BIT_AND|BIT_COUNT|BIT_LENGTH|BIT_OR|BIT_XOR|STD|STDDEV|STDDEV_POP|STDDEV_SAMP|VAR_POP|VAR_SAMP|VARIANCE)/ )
			{
				$aggregate = 1;
			}
			else {
				$field_names{$1} = 1;
				$non_aggregate = 1;
			}
		}
	}
	my $aggregate_mix = $aggregate && $non_aggregate;

	debug "Aggregate mix: $aggregate_mix\n";

	if ( $aggregate_mix and $query !~ /GROUP\s+BY/i ) {
		debug "Mix of aggregate and non-aggregate without GROUP BY\n";
		return 0;
	}

	if ( $query =~ /\WGROUP\s+BY\s+(.*?)(?:ASC|DESC|WITH|HAVING|ORDER\s|LIMIT|PROCEDURE|INTO|FOR\s)/i )
	{
		my $fields = $1;
		my @field_list = split /[,\s]/, $1;
		my %groupby_names;
		foreach my $f ( @field_list ) {
			if ( $f =~ /^\w+$/ and $mismatch eq 'content' and not exists $field_names{$f} and not exists $alias_names{$f} )
			{
				debug "GROUP BY contains field $f which is not in the field list\n";
				return 0;
			}
			$groupby_names{$f} = 1;
		}
		if ( $aggregate_mix ) {
			foreach my $n ( keys %field_names ) {
				unless ( defined $groupby_names{$n} or defined $groupby_names{$field_aliases{$n}} ) {
					debug "Mix of aggregate and non-aggregate, and field list contains field $n which is not in GROUP BY\n";
					return 0;
				}
			}
		}

	}

	if ( $query =~ /\WORDER\s+BY\s+(.*?)(?:LIMIT|PROCEDURE|INTO|FOR\s)/i )
	{
		my $fields = $1;
		$fields =~ s/\s(?:ASC|DESC)//g;
		my @field_list = split /[,\ ]/, $fields;
#		debug "ORDER BY list: @field_list\n";
		foreach my $f ( @field_list ) {
			$f =~ s/\s//g;
			if ( $mismatch eq 'content' and not $field_names{$f} and not $alias_names{$f} )
			{
				debug "   In (sub)query \n     $query \n       ORDER BY contains field $f which is not in the field list\n";
				return 0;
			}
		}
	}

	if ( $query =~ /LIMIT/ and $query !~ /ORDER\s+BY/i )
	{
		debug "Query contains LIMIT without ORDER BY\n";
		return 0;
	}

#	print "Query legitimate\n";
	return 1;

}

sub extract_subqueries
{
	my ( $query, $query_num ) = @_;
	my ( $prefix, $subquery, $suffix ) = ( '', '', '' );
	if ( $query =~ /^(\s*SELECT.*)\(\s*(SELECT.*)$/ )
	{
		$prefix = $1;
		my @items = split /\s+/, $2;
		my $level = 0;
		my $in_suffix = 0;
#		print "Parsing query: \n$query\n";
#		print "Prefix: \n$prefix\n";
		foreach my $i ( @items )
		{
#			print "HERE: Next element: $i level $level\n" if $query_num == 5;
			if ( $in_suffix ) {
				$suffix .= ' '.$i;
			}
			elsif ( $i eq '(' ) {
				$level++;
				$subquery .= ' (';
			}
			elsif ( $i eq ')' and ! $level ) {
				$in_suffix = 1;
			}
			elsif ( $i eq ')' ) {
				$level--;
				$subquery .= ' '.$i;
			}
			else {
				$subquery .= ' ' .$i;
			}
		}
		$query = $prefix . ' __subquery_' . $query_num . '__' . $suffix;
#		debug "__subquery_".$query_num . ": " . $subquery . "\n";
		return ( $subquery, extract_subqueries( $query, $query_num+1) );
	}
	else {
		return ( $query );
	}
}


