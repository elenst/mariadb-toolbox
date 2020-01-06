use strict;

# The following clean ups are performed:
#
# 1)
# --connection X
#   <query>
#   ....
# --connection X
# The second connection X is removed
#
# 2) reap without pending send, reap is removed
#
# 3)
# --send
# --send
#   <query>
# Extra send is removed
#
# 4)
# --send
#   <query>
# --send
#   <query>
# A reap is added before the 2nd send

# 5)
# --send
#   <query>
# --reap
# It it happens, we should remove send and reap.
#
# 6)
# --connection X
# --connection Y
# Switching to connection X is not needed.



# Pending query appears when we have the construction
# --send
#   <query>
# (the <query> part will go to $pending_query, and we'll know there was a send before)
# This is for cases 4) and 5)
# If we find one of these sequences, we will forget the pending send and will just print the query.
# But if the next line is a connection switch, we will print the query with send/
my $pending_query = '';

# Hash connection_id => (1 | 0)
# We will remember all connections where we printed
# --send
#   <query>
# but did not print a reap yet.
my %con_sends = ();

# The current connection number (from the last --connection or --connect command)
my $cur_con = '';

# Last line from the input
my $ln = '';

my $debug = 0;

sub debug {
    print STDERR @_ if ($debug);
}

LINE:
do
{
    debug "LINE: $ln" if $ln;

    if ( $ln =~ /^\s*$/ ) {
      print $ln;
    }
    # Some commands shouldn't anyhow change the logic of sends/reaps,
    # just keep them as is and in further consideration
    # TODO: the list is to be extended
    elsif ( $ln =~ /^\s*\-\-\s*delimiter|sleep|let/ ) {
      if ($pending_query) {
        $pending_query .= $ln;
      } else {
        print $ln;
      }
    }
    elsif ( $ln =~ /^\s*\-\-connection\s+(\w+)/ or $ln =~ /^\s*\-\-connect\s*\((\w+)/ )
    {
        debug "   line is a connection or connect\n";
        my $new_con = $1;
        # check that it's not the same as current connection
        # if it is, ignore, otherwise remember the connection name and print

        # now, check if there is a pending query in the previous connection,
        # if there is, print it with --send
        if ( $pending_query ) {
            debug "   found a pending query for connection $cur_con, printing it and cleaning up\n";
            print "--send\n$pending_query";
            $con_sends{$cur_con} = 1;
            $pending_query = '';
        }

        if ( $ln =~ /connection/ )
        {
            debug "   line is a connection\n";
            # Check that this connection switch is not empty, that there is an actual work after it,
            # not another connection switch; ignore it if it's empty or if it switches to itself
            my $ln1 = <>;
            exit unless defined $ln1;
            debug "   NEXT LINE: $ln1\n";

            # First condition is to cover case (6) from the description -- if there are two connection commands in a row, ignore the first one
            # Second condition is to cover case (1)
            if ( $ln1 !~ /^\s*\-\-connection\s+/ and $new_con ne $cur_con )
            {
                debug "   ln1 is not connection printing line '$ln', updating cur_con\n";
                print $ln;
                $cur_con = $new_con;
                # if there was a --send for this new connection, it's time to say --reap
                if ( $con_sends{$cur_con} ) {
                    debug "   Found an open send for $cur_con, printing reap\n";
                    print "--reap\n";
                    $con_sends{$cur_con} = 0;
                }
            }
            debug "   Updating ln with '$ln1' and going to the next step\n";
            $ln = $ln1;
            goto LINE;
        }
        else {
            # If it was a new connect, print it and update cur_con
            debug "   ln was connect '$ln', printing it\n";
            print $ln;
            $cur_con = $new_con;
        }
    }

    elsif ( $ln =~ /^\s*\-\-disconnect\s*(\w+)/ )
    {
        if ( $pending_query )
        {
            print "$pending_query";
            $pending_query = '';
        }
        # if there was a --send for this connection, say --reap before disconnecting
        if ( $con_sends{$1} ) {
            unless ($cur_con and $cur_con eq $1) {
                print "--connection $1\n";
            }
            print "--reap\n";
        }
        # Now print --disconnect and forget the connection
        print $ln;
        delete $con_sends{$1};
        $cur_con = '';
    }

    elsif ( $ln =~ /^\s*\-\-reap/ )
    {
        # if there is a pending query, it means we can ignore the whole send-reap business, and
        # just print the query -- case (5) from the description
        if ( $pending_query )
        {
            print "$pending_query";
            $pending_query = '';
        }
        # if there is an open --send, print this --reap, otherwise ignore -- case (2) from the description
        elsif ( $con_sends{$cur_con} ) {
            print $ln;
            $con_sends{$cur_con} = 0;
        }
    }

    elsif ( $ln =~ /^\s*\-\-send/ )
    {
        # if there is a pending query, we'll ignore the first send, print the query, and proceed
        if ( $pending_query )
        {
            print $pending_query;
            $pending_query = '';
        }
        # if --send, check that there was no --send already
        elsif ( $con_sends{$cur_con} ) {
            # if there was, need to do --reap before the next send -- case (4) from the description
            print "--reap\n";
            $con_sends{$cur_con} = 0;
        }
        # if --send is the last line in the file, just don't do anything,
        # the loop will finish at 'while' below
        unless (eof) {
            # now, check that there is an actual query after this send, otherwise just ignore --case (3) from the description
            my $ln1 = <>;
            if ( $ln1 =~ /^\s*\-\-/ )
            {
                $ln = $ln1;
                goto LINE;
            }
            else
            {
                $pending_query = $ln1;
            }
        }
    }
    else {
        # if there is a pending query, just print that query, and then print the line
        if ( $pending_query )
        {
            print $pending_query;
            $pending_query = '';
        }
        print $ln;
    }
}
while ($ln = <>);
if ($pending_query) {
  print "--send\n$pending_query";
}

