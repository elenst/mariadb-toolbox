use strict;

# type should be stmt or line
my $type = shift @ARGV;
my $test = shift @ARGV;
my $output = shift @ARGV;

open( TEST, "t/$test.test" ) or die "could not open t/$test.test for reading: $!";

my @test = ();

while (<TEST>)
{
	if ( /^--/s ) 
	{
		push @test, $_;
	}
	elsif ( /^\s*\#/s )
	{
		next;
	}
	elsif ( /^\s*$/ )
	{
		next;
	}
	else {
		my $cmd = $_;
		if ( $type eq 'stmt' )
		{
			while ( $cmd !~ /;/s ) 
			{
				$cmd .= <TEST>;
			}
		}
		push @test, $cmd;
	}
}

close( TEST );

my $reproducible_counter = 0;
my $not_reproducible_counter = 0;

print "Running initial test\n";
unless ( run_test( \@test ) )
{
	print "The initial test didn't fail!\n\n";
	exit;
}

my $chunk_size = 1;
while ( $chunk_size*10 < scalar( @test ) )
{
	$chunk_size *= 10;
}

my @needed_part = @test;

while ( $chunk_size > 0 )
{
        print "\n\nNew chunk size: $chunk_size\n";
	@test = @needed_part;
	@needed_part = ();

	my $next_unchecked = 0;

	while ( $next_unchecked <= $#test )
	{
		my $end_of_chunk = min($next_unchecked+$chunk_size-1,$#test);
		
		my @chunk = @test[$next_unchecked..$end_of_chunk];
		print "\nNext chunk to remove ($next_unchecked .. $end_of_chunk), out of $#test \n";
		my @preserved_part = ();
		foreach my $l ( @chunk )
		{
			if ( $l =~ /\#\s+PRESERVE/i )
			{
				push @preserved_part, $l;
			}
		}
		if ( scalar( @preserved_part ) < scalar( @chunk ) )
		{ 	
			my @new_test = ( @needed_part, @preserved_part, @test[$end_of_chunk+1..$#test] );

			if ( run_test( \@new_test ) )
			{
				print "Chunk $next_unchecked .. $end_of_chunk is not needed\n";
				if ( @preserved_part )
				{
					print "Preserving " . scalar( @preserved_part ) . " lines in the chunk\n";
					push @needed_part, @preserved_part;
				}
			}
			else {
				print "Saving chunk  $next_unchecked .. $end_of_chunk\n";
				push @needed_part, @chunk;
			}
		}
		else {
			push @needed_part, @preserved_part;
		}
		$next_unchecked = $end_of_chunk+1;
	}
	$chunk_size = int( $chunk_size/2 );
}

# Returns 1 if the test fails as expected,
# and 0 otherwise
sub run_test
{
	my $testref = shift;
	print "Size of the test to run: " . scalar(@$testref) . "\n";
	open( TEST, ">t/new_test.test" ) or die "Could not open t/new_test.test for writing: $!";
	print TEST "--disable_abort_on_error\n";
	#print TEST "--source include/master-slave.inc\n";
	#print TEST "--source include/have_binlog_format_statement.inc\n";
        print TEST @$testref;
	#print TEST "\n--sync_slave_with_master\n";
        close( TEST );
	my $start = time();
        my $out = readpipe( "perl ./mtr @ARGV new_test" );
        $out .= readpipe("cat var/log/mysqld.1.err");
	if (-e 'var/log/mysqld.2.err') {
        $out .= readpipe("cat var/log/mysqld.2.err");
	}
	my $outfile;
	my $result = ( $out =~ /$output/ );
	if ( $result )
	{
		print "Reproduced (no: $reproducible_counter)\n";
		rename( "t/new_test.test", "t/$test.test.reproducible.$reproducible_counter" );
		$outfile = "$test.out.reproducible.$reproducible_counter";
		$reproducible_counter++;
	}
	else {
		$outfile = "$test.out.not_reproducible.$not_reproducible_counter";
		print "Could not reproduce\n";
		$not_reproducible_counter++;
	}
	print "Test time: " . ( time() - $start ) . "\n";
	open( OUT, ">$outfile" ) || die "Could not open $outfile for writing: $!";
	print OUT $out;
	close( OUT );
	return $result;
}

sub min 
{
	return ( $_[0] < $_[1] ? $_[0] : $_[1] );
}
