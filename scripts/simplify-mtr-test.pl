use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use File::Copy "copy";

use strict;

my $opt_mode = 'all';
my $output = 'signal ';
my $suitedir = 't';
my $suitename;
my $options = '';
my $testcase;
my $path = dirname(abs_path($0));
my $opt_preserve_connections;

my @preserve_connections;
my %preserve_connections;

my @modes;

if ($^O eq 'MSWin32' or $^O eq 'MSWin64') {
  require Win32::API;
  my $errfunc = Win32::API->new('kernel32', 'SetErrorMode', 'I', 'I');
  my $initial_mode = $errfunc->Call(2);
  $errfunc->Call($initial_mode | 2);
}

GetOptions (
    "testcase=s"  => \$testcase,
    "mode=s"      => \$opt_mode,
    "output=s"    => \$output,
    "suitedir=s"  => \$suitedir,
    "suite=s"     => \$suitename,
    "options=s"   => \$options,
    "preserve_connections=s" => \$opt_preserve_connections,
    "preserve-connections=s" => \$opt_preserve_connections,
);



if (!$testcase) {
    print "ERROR: testcase is not defined\n";
    exit 1;
}

if (lc($opt_mode) eq 'all') {
	@modes= ('conn','stmt','line');
} elsif ($opt_mode =~ /^(stmt|line|conn)/i) {
	@modes= lc($1);
} else {
    print "ERROR: Unknown simplification mode: $opt_mode. Only 'stmt', 'line', 'conn', 'all' are allowed\n";
    exit 1;
}

if ($opt_preserve_connections) {
	@preserve_connections = split /,/, $opt_preserve_connections;
	foreach ( @preserve_connections ) { $preserve_connections{$_} = 1 };
}

unless ($suitename) {
    if ($suitedir eq 't') {
        $suitename = 'main'
    }
    elsif ($suitedir =~ /.*[\/\\](.*)/) {
        $suitename = $1;
    }
    else {
        print "ERROR: Could not retrieve suite name\n";
        exit 1;
    }
}

if ($ENV{MTR_VERSION} eq "1" and ($suitename eq 't' or $suitename eq 'main') and not -e "r/new_test.result") {
    system("touch r/new_test.result");
}

copy("$suitedir/$testcase.test","$suitedir/new_test.test") || die "Could not copy $suitedir/$testcase.test to $suitedir/new_test.test";

my $reproducible_counter = 0;
my $not_reproducible_counter = 0;

my ($test, $connections) = read_testfile("$suitedir/new_test.test",$modes[0]);

print "Running initial test\n";
unless (run_test($test))
{
    print "The initial test didn't fail!\n\n";
    exit;
}

my @last_failed_test= @$test;

foreach my $mode (@modes)
{
	print "\n\n====== mode: ".uc($mode)." ========\n";

	if ($mode eq 'conn')
	{
		# Connection mode is always first, no need to re-read the test file

		print "\nTotal number of connections: " . scalar(@$connections) . "\n\n";

		my $skip= 0;
		foreach my $c (@$connections)
		{
			if ($preserve_connections{$c}) {
				print "\nPreserving connection $c\n";
				next;
			}
			print "\nNext connection to remove: $c\n";

			my @new_test = ();
			foreach my $t (@last_failed_test) {
				if ( $t =~ /^\s*\-\-(?:connect\s*\(\s*|disconnect\s+|connection\s+)([^\s\,]+)/s )
				{
					$skip = ( $1 eq $c );
					#print STDERR "COnnection $1 - in hash? $connections{$1}; ignore? $ignore\n";
				}
				push @new_test, $t unless $skip;
			}
			if (run_test(\@new_test)) {
				print "Connection $c is not needed\n";
				@last_failed_test= @new_test;
			} else {
				print "Saving connection $c\n";
			}
		}
	}
	else
	{
		# Re-read the test in the new mode
		write_testfile(\@last_failed_test);
		# We don't need connections (second returned value) anymore
		($test, undef)= read_testfile("$suitedir/new_test.test",$mode);

		my @test= @$test;
		if (scalar(@test) <= 1) {
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
					if ( $l =~ /\#\s+PRESERVE/i or $l =~ /^\s*(?:if|while|{|}|--let|--dec|--inc|--eval)/ )
					{
						push @preserved_part, $l;
					}
				}
				if ( scalar( @preserved_part ) < scalar( @chunk ) )
				{
					print "Creating new test as a combination of needed part (".scalar(@needed_part)." lines), preserved part (".scalar(@preserved_part)." lines), and test from ".($end_of_chunk+1)." to $#test\n";
					my @new_test = ( @needed_part, @preserved_part, @test[$end_of_chunk+1..$#test] );

					if ( run_test( \@new_test ) )
					{
						@last_failed_test= @new_test;
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
	}
}

print "\nLast reproducible testcase: $suitedir/$testcase.test.reproducible.".($reproducible_counter-1)."\n\n";

# THE END


# Returns 1 if the test fails as expected,
# and 0 otherwise
sub run_test
{
    my $testref = shift;
    print "Size of the test to run: " . scalar(@$testref) . "\n";

    write_testfile($testref);
    my $start = time();
    my $out = readpipe( "perl mysql-test-run.pl $options --suite=$suitename new_test" );
    my $errlog = ( $ENV{MTR_VERSION} eq "1" ? 'var/log/master.err' : 'var/log/mysqld.1.err');

	my $separ= $/;
	$/= undef;
	open(ERRLOG, "$errlog") || die "Cannot open $errlog\n";
	$out.= <ERRLOG>;
	close(ERRLOG);
    if (-e 'var/log/mysqld.2.err') {
		open(ERRLOG, "var/log/mysqld.2.err") || die "Cannot open var/log/mysqld.2.err\n";
		$out.= <ERRLOG>;
		close(ERRLOG);
    }
	$/= $separ;
    my $outfile;
    my $result = ( $out =~ /$output/ );
    if ( $result )
    {
        print "Reproduced (no: $reproducible_counter)\n";
        copy("$suitedir/new_test.test", "$suitedir/$testcase.test.reproducible.$reproducible_counter") || die "Could not copy $suitedir/new_test.test to $suitedir/$testcase.test.reproducible.$reproducible_counter: $!";
        $outfile = "$testcase.out.reproducible.$reproducible_counter";
        $reproducible_counter++;
    }
    else {
        $outfile = "$testcase.out.not_reproducible.$not_reproducible_counter";
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

sub write_testfile
{
	my $testref= shift;
    open( TEST, ">$suitedir/new_test.tmp" ) or die "Could not open $suitedir/new_test.tmp for writing: $!";
    print TEST "--disable_abort_on_error\n";
    #print TEST "--source include/master-slave.inc\n";
    #print TEST "--source include/have_binlog_format_statement.inc\n";
    print TEST @$testref;
    #print TEST "\n--sync_slave_with_master\n";
    close( TEST );
    system("perl $path/cleanup_sends_reaps.pl $suitedir/new_test.tmp > $suitedir/new_test.test");
}

sub read_testfile
{
	my ($testfile, $mode)= @_;
	my %connections= ();
	my @test= ();
	my $current_con= '';
	open( TEST, $testfile ) or die "could not open $testfile for reading: $!";
	while (<TEST>)
	{
		if ( /^\s*--/s )
		{
			# SQL comments or MTR commands
			push @test, $_;
			if (/^\s*\-\-\s*connect\s*\(\s*([^\s\,]+)/s) {
				$connections{$1} = 0;
				$current_con= $1;
			} elsif ( /^\s*\-\-\s*connection\s+(\S+)/s) {
				$current_con= $1;
			}
			$connections{$current_con}++;
		}
		elsif ( /^\s*\#/s )
		{
			# Comment lines not needed
			next;
		}
		elsif ( /^\s*$/ )
		{
			# Empty lines not needed
			next;
		}
		elsif ( /^\s*(?:if|while)\s*\(/s )
		{
			# MTR's if/while constructions, leave them as is for now
			push @test, $_;
			$connections{$current_con}++;
		}
		elsif ( /^\s*(?:\{|\})/s )
		{
			# Brackets from MTR's if/while constructions
			push @test, $_;
			$connections{$current_con}++;
		}
		else {
			my $cmd = $_;
			if ( $mode eq 'stmt' or $mode eq 'conn' )
			{
				while ( $cmd !~ /;/s )
				{
					$cmd .= <TEST>;
				}
			}
			push @test, $cmd;
			$connections{$current_con}++;
		}
	}
	close( TEST );


	my @connections= ();
	# Only bother to sort connections by usage if operate in connection mode
	if ($mode eq 'conn') {
		# Make sure that values are unique, so that we can invert the hash safely
		foreach my $k (keys %connections) {
			$k =~ /con(\d+)/;
			$connections{$k}+= $1/1000;
		}
		my %lengths= reverse %connections;
		foreach my $k (reverse sort {$a<=>$b} keys %lengths) {
			push @connections, $lengths{$k};
		}
	}

	return (\@test, \@connections);
}
