use Time::Local;
use Getopt::Long;
use strict;


my $opt_load_dir;
my $opt_tables;
my $opt_sleep = 1;

GetOptions ( 	
			"load-dir=s"            => \$opt_load_dir,
			"tables=s"              => \$opt_tables,
			"sleep!"                => \$opt_sleep,
			);

my @files = @ARGV;

$opt_load_dir =~ s/[\\\/]$//;
						
my $cur_test_con = 0;

# Connection number as a key in the hash means that the thread is connected.
# If the value is 0, it means the connection is idle (no current --send).
# If the value is 1, it means the connection is doing --send and hence --reap is required
# before the connection can do anything else (including disconnect).
my %test_connections = ();

my %user_passwords = ();

my $last_log_sec = 0;

my $cur_log_con = 0;
my $cur_log_record = '';

# TODO: how to handle KILL <con num>?
# TODO: MYSQLTEST_VARDIR 

my %interesting_connections;

if ( $opt_tables ) 
{
	# We are interested only in connections which have something to do with 
	# the listed tables. So, we'll look through the log first, find 
	# the list of connections, and then will process only those we chose
	
	$opt_tables =~ s/,/\|/g;
	my $pattern = qr/($opt_tables)/;
	my $cur_con;

	while (<>) 
	{
		if ( /^\s*[\d\:\s]*\s+(\d+)\s+Query/ ) {
			$cur_con = $1;
		}
		$interesting_connections{$cur_con} = 1
			if /$pattern/;
	} 
	unless ( scalar( keys %interesting_connections) ) {
		print STDERR "Requested tables not found in the log\n";
		exit 1;
	}
	@ARGV = @files;
}


# TODO: By default there will be some special hacks for system tests. Add an option to switch them off
my $systest_partition_folders_created = 0;

print "--source include/have_innodb.inc\n";
print "--enable_connect_log\n";
print "--disable_abort_on_error\n";
print "SET GLOBAL event_scheduler = OFF;\n";

#foreach my $c ( keys %interesting_connections ) {
#	print "$c\n";
#}

# The flag will be used if we are only interested in certain connections
my $ignore;

LOGLINE:
while(<>) {
        my $new_log_con;
        my $new_log_timestamp;
        my $new_log_record_type;
        
        # Stripping the timestamp if exists
        if ( s/^(\d{6}\s+\d+:\d\d:\d\d)\s*// ) 
        {
                $new_log_timestamp = $1;
        }

        # Presence of a connection number and record type 
        # means the line is a start of a record
        
        if ( s/^\s*(\d+)\s+(\w+)// ) 
        {
                $new_log_con = $1;
                $new_log_record_type = $2;
                
                if ( scalar( keys %interesting_connections )
                		and not $interesting_connections{$new_log_con} ) 
             	{
                	$ignore = 1;
                	next LOGLINE;		
               	}
               	$ignore = 0;
				
				# If we have built a previous record (possibly from several lines),
				# now it's time to print it
				
				print_current_record( $new_log_con );
				
				if ( $new_log_timestamp )
				{
					# By default we try to make the flow similar to the initial.
					# Since we don't put 'real_sleep', anybody who wants to ignore the delays
					# can later override sleep time from MTR command line
					
	                my $new_log_sec = time_to_sec( $new_log_timestamp );
	                if ( $opt_sleep and $last_log_sec and ( my $dif = ( $new_log_sec - $last_log_sec - 1 ) > 0 ) ) {
	                	print "--sleep $dif\n";
	                }
	                $last_log_sec = $new_log_sec;
				}

                # We ignore Prepare, Execute, Statistics and Binlog lines
        		next LOGLINE if ( $new_log_record_type =~ /(?:Prepare|Execute|Binlog|Field|Statistics|Shutdown)/ );        
        		
        		if ( $new_log_record_type eq 'Connect' ) 
        		{
        			# Log record 'Connect' translates into --connect
        			# and also changes current connection in the test
        			 
        			my ( $user, $host, $db ) = ( $_ =~ /^\s*([^\@]+)\@(\S+)\s+(?:as.*?\s+)?on\s*(\S*)/ );
        			$db = '' unless defined $db;
        			my $conname = 'con' . $new_log_con;
        			my $password = ( defined $user_passwords{$user.'@'.$host} ? $user_passwords{$user.'@'.$host} : '' );
        			print "--connect ($conname,$host,$user,$password,$db)\n";
        			print "--let \$${conname}_id = `SELECT CONNECTION_ID() AS ${conname}`\n";
        			$test_connections{$new_log_con} = 0;
        			$cur_test_con = $new_log_con;
        		}
        		elsif ( $new_log_record_type eq 'Quit' ) 
        		{
        			# Log record 'Quit' translates into --disconnect.
        			# TODO: There was a problem with disconnect in RQG tool which I had to fix,
        			# but I don't remember what it was -- something about losing the current
        			# test connection after unfortunate disconnect. Leaving it as is now,
        			# but will have to get back to it when the test starts failing

        			my $conname = 'con' . $new_log_con;
					if ( $test_connections{$new_log_con} ) 
					{
						print "--connection $conname\n";
						print "--reap\n";
					}
        			print "--disconnect $conname\n";
        			delete $test_connections{$new_log_con};
        			$cur_test_con = 0;
        		}
        		elsif ( $new_log_record_type eq 'Change' ) 
        		{
        			# Log record 'Change' translates into --change_user
        			# and also changes current connection in the test
        			 
        			my ( $user, $host, $db ) = ( $_ =~ /^\s*user\s+(\w+)\@(\S+)\s+(?:as.*?\s+)?on\s*(\w*)/ );
        			$db = '' unless defined $db;
        			my $conname = 'con' . $new_log_con;
					print "--connection $conname\n";
					if ( $test_connections{$new_log_con} ) 
					{
						print "--reap\n";
						$test_connections{$new_log_con} = 0;
					}
        			my $password = ( defined $user_passwords{$user.'@'.$host} ? $user_passwords{$user.'@'.$host} : '' );
        			print "--change_user $user,$password,$db\n";
        			$cur_test_con = $new_log_con;
        		}
        		elsif ( $new_log_record_type eq 'Query' ) 
        		{
        			$cur_log_con = $new_log_con;
        			$cur_log_record = $_;
        		}
				elsif ( $new_log_record_type eq 'Init' and /\s*DB\s*(.*)/ ) 
				{
					my $conname = 'con' . $new_log_con;
					my $db_name = $1;
               if ( $test_connections{$new_log_con} )
               {
                 	print "--connection $conname\n";
						print "--reap\n";
						$test_connections{$new_log_con} = 0;
					}
	        		$cur_log_con = $new_log_con;
					$cur_log_record = "CREATE DATABASE IF NOT EXISTS $db_name ;\nUSE $db_name;\n";
				}
        		else {
        			print "ERROR: Unknown record type: $new_log_record_type\n";
        			exit 1;
        		}
        } # end if <new record>
        elsif ( $ignore ) {
        	# This is a continuation of a line we decided to ignore
        	next LOGLINE;
        }
        elsif ( $cur_log_record ) {
        	$cur_log_record .= ' ' . $_;
        }
        else {
        	# This is something else, for example start records in the log. Can print it here 
        	# for investigation purposes
        	# print "HERE: Something else:\n$_";
        }
}

print_current_record($cur_log_con);

foreach my $c ( keys %test_connections ) {
	if ( $test_connections{$c} ) {
		print "--connection con", $c, "\n";
		print "--reap\n";
	}
}
print "--exit\n";



sub system_test_hacks
{
	my $log_record_ref = shift;
	
	my $needs_eval = 0;
	
	if ( $$log_record_ref =~ s/^\s*(kill(?:\s+query)?)\s+(\d+)/eval $1 \$con${2}_id/is ) {
		return 0;
	}

        if ( $$log_record_ref =~ s/^\s*(show\s+explain\s+for)\s+(\d+)/eval $1 \$con${2}_id/is ) {
                return 0;
        }
	
	if ( $$log_record_ref =~ /^\s*(?:insert(?: DELAYED)? into table_logs.tb\d_logs|insert into tbnum0_log|insert into tbnum0pk_eng\d_child|insert into tbstr\d_log|INSERT INTO celosia_features.t_celosia_log)/ ) {
		$$log_record_ref = '';
		return 0;
	}
	if ( $$log_record_ref =~ s/\'[-\w\/\\]+(\/|\\)master-data-partitions/\'\$MYSQLTEST_VARDIR/sg ) {
		unless ( $systest_partition_folders_created ) 
		{
			print "--mkdir \$MYSQLTEST_VARDIR/master-data-partitions\n"; 
			print "--mkdir \$MYSQLTEST_VARDIR/master-data-partitions/tmpdata\n"; 
			print "--mkdir \$MYSQLTEST_VARDIR/master-data-partitions/tmpindex\n";
			$systest_partition_folders_created = 1; 
		}
		$needs_eval = 1; # hacks applied, "eval needed"
	}

	if ( $opt_load_dir ) 
	{
		# In regexp:
		# a) First () is LOAD DATA [LOCAL] INFILE [commas or whatever] '
		# b) Next []+ is the file location (without the file name)
		# c) Next () is a path separator, either \ or /
		# d) Next () is the file name
		# e) Everything ends with '
		# We want to replace (b) with the opt_load_dir value without changing the rest 
		$$log_record_ref =~ s/(LOAD\s+DATA\s+(?:LOCAL)?\s+INFILE\W*\')[-\w\/\\]+(\\|\/)([^\\\/\']+)\'/${1}${opt_load_dir}${2}${3}\'/igs;
	}
	
	return $needs_eval; 
}

sub time_to_sec
{
	my $ts = shift;
	my ( $year, $month, $day, $hour, $min, $sec ) 
		= ( $ts =~ /(\d\d)(\d\d)(\d\d)\s+(\d+):(\d\d):(\d\d)/ );
	
	return timelocal( $sec, $min, $hour, $day, $month-1, $year );
}


sub print_current_record
{
	my $new_log_con = shift;
	if ( $cur_log_record ) 
	{
		if ( ! exists( $test_connections{$cur_log_con} ) )
		{
			print "--connect (con$cur_log_con,localhost,root,,test)\n";
			print "--let \$con${cur_log_con}_id = `SELECT CONNECTION_ID() AS con${cur_log_con}`\n";
			$test_connections{$cur_log_con} = 0;
			$cur_test_con = $cur_log_con;
		}
		elsif ( $cur_log_con != $cur_test_con ) {
			print "--connection con" . $cur_log_con . "\n";
			$cur_test_con = $cur_log_con;
		}
		
		if ( $test_connections{$cur_log_con} ) {
			print "--reap\n";
			$test_connections{$cur_log_con} = 0;
		}
		chomp $cur_log_record;
		if ( system_test_hacks(\$cur_log_record) )
                {
                        print "eval ";
                }
		if ( $cur_log_record )
		{	
			my $delimiter = ( $cur_log_record =~ /;/ ? '|||' : ';' ); 
			if ( $delimiter eq '|||' ) {
				print "--delimiter |||\n";
			}
	
			if ( $cur_log_con != $new_log_con and !( $cur_log_record =~ /^\s*LOAD DATA/ ) )
			{
				# Whenever log connection changes, we will do --send
				print "--send\n";
				$test_connections{$cur_log_con} = 1;
			}
		
			print $cur_log_record, $delimiter, "\n";
			if ( $delimiter ne ';' ) {
				print "--delimiter ;\n";
			}
		}	
		if ( $cur_log_record =~ /set\s+password\s+for\s+\'?(\w+)\'?\@\'?(\w+)\'?\s*=\s*password\s*\(\s*\'(\w+)\'\s*\)/ ) 
		{
			$user_passwords{$1.'@'.$2} = $3;
		} 
	
		$cur_log_record = ''; 
		# The next is not necessary, but it might make debugging easier
		$cur_log_con = 0;
	}
}

