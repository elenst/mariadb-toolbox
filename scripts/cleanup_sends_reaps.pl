use strict;

my $pending_send = '';
my %con_sends = ();
my $cur_con = '';

my $ln = '';

LINE:
do
{
	if ( $ln =~ /\-\-connection\s*(\w+)/ or $ln =~ /\-\-connect\s*\((\w+)/ ) 
	{
		# check that it's not the same as current connection
		# if it is, ignore, otherwise remember the connection name and print
		unless ( $1 eq $cur_con )
		{
			# now, check that there is no pending --send in the previous connection
			if ( $pending_send ) {
				print "--send\n$pending_send";
				$con_sends{$cur_con} = 1;
				$pending_send = 0;
			}
			$cur_con = $1;
			print $ln;
			# if there was a --send for this new connection, it's time to say --reap
			if ( $con_sends{$cur_con} ) {
				print "--reap\n";
				$con_sends{$cur_con} = 0;
			}
		}	
	}

	elsif ( $ln =~ /\-\-reap/ ) 
	{
		# if there is a pending send, it means we can ignore the whole send-reap business, and
		# just print the query
		if ( $pending_send )
		{
			print "$pending_send";
			$pending_send = 0;
		}	
		elsif ( $con_sends{$cur_con} ) {
		# we only re-print --reap if there is an open --send, otherwise just ignore
			print $ln;
			$con_sends{$cur_con} = 0;
		}
	}
	
	elsif ( $ln =~ /\-\-send/ ) 
	{
		# if there is a pending send, we'll ignore the first send, print the query, and proceed
		if ( $pending_send )
		{
			print $pending_send;
			$pending_send = 0;
		}
		# if --send, check that there was no --send already
		elsif ( $con_sends{$cur_con} ) {
		# if there was, need to do --reap before the next send
			print "--reap\n";
			$con_sends{$cur_con} = 0;
		}

		# now, check that there is an actual query after this send, otherwise just ignore --send
		my $ln1 = <>;
		if ( $ln1 =~ /^\-\-/ )
		{
			$ln = $ln1;
			goto LINE;
		}
		else
		{
			$pending_send = $ln1;
		}
	}
	else {
		# if there is a pending send, just print that query
		if ( $pending_send )
		{
			print $pending_send;
			$pending_send = 0;
		}
		print $ln;
	}
}
while ($ln = <>);

