#!/usr/bin/perl

# Copyright (c) 2022, Elena Stepanova and MariaDB
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1335  USA

use Time::Local;
use Getopt::Long;
use strict;


my $opt_tables;
my $opt_sleep= 1;
my $opt_threads= '';
my $opt_timestamps= 0;
my $opt_convert_to_ei= 0;
my $opt_convert_to_ps= 0;
my $opt_sigkill= 0;
my $opt_data_location= '';
my $opt_rpl= 0;
my $enable_result_log= 0;

GetOptions (
  "tables=s"         => \$opt_tables,
  "sleep!"           => \$opt_sleep,
  "timestamps!"      => \$opt_timestamps,
  "threads=s"        => \$opt_threads,
  "connections=s"    => \$opt_threads,
  "convert-to-execute-immediate|convert_to_execute_immediate|convert-to-ei|convert_to_ei" => \$opt_convert_to_ei,
  "convert-to-ps|convert_to_ps" => \$opt_convert_to_ps,
  "enable_result_log|enable-result-log" => \$enable_result_log,
  "sigkill!"         => \$opt_sigkill,
  "data-location|data_location=s" => \$opt_data_location,
  "rpl!" => \$opt_rpl,
  );

my %interesting_connections= map { $_ => 1 } split /,/, $opt_threads;
my $interesting_tables_pattern= ($opt_tables ? qr/($opt_tables)/ : undef);

my @files= @ARGV;

my $cur_test_con= 0;

# Connection number as a key in the hash means that the thread is connected.
# If the value is 0, it means the connection is idle (no current --send).
# If the value is 1, it means the connection is doing --send and hence --reap is required
# before the connection can do anything else (including disconnect).
my %test_connections= ();

my %user_passwords= ();
my $last_log_sec= 0;
my $cur_log_con= 0;
my $cur_log_record= '';
my $timestamp= 0;
my $server_restarts= 0;
my $orig_data_location= '';
my %service_connections= (); # Spider connections and such, to be ignored

# Maximum connection ID used in the current server run.
# The value is changed to 0 when the server is restarted.
# It is used to determine whether log rotation lines represent server restart
# or FLUSH LOGS result.
my $max_used_connection_id= 0;

# TODO: how to handle KILL <con num>?
# TODO: MYSQLTEST_VARDIR

if ( $interesting_tables_pattern )
{
  # We are interested only in connections which have something to do with
  # the listed tables. So, we'll look through the log first, find
  # the list of connections, and then will process only those we chose

  my $cur_con;

  while (<>)
  {
    if ( /^\s*[\d\:\s]*\s+(\d+)\s+(?:Query|Prepare)/ ) {
      $cur_con= $1;
    }
    $interesting_connections{$cur_con}= 2
    if /$interesting_tables_pattern/ and ($opt_threads eq '' or defined $interesting_connections{$cur_con});
  }
  foreach ( keys %interesting_connections ) {
    delete $interesting_connections{$_} unless $interesting_connections{$_} == 2
  };
  unless ( scalar( keys %interesting_connections) ) {
    print STDERR "Requested tables not found in the log\n";
    exit 1;
  }
  @ARGV= @files;
}

print "--source include/have_innodb.inc\n";
print "--enable_connect_log\n";
unless ($enable_result_log) {
  print "--disable_result_log\n";
}
if ($opt_rpl) {
  print "--source include/master-slave.inc\n";
}
print "--disable_abort_on_error\n";
print "USE test;\n";
print '--let $charset= `SELECT @@character_set_server`'."\n";
print '--let $collation= `SELECT @@collation_server`'."\n";
print '--eval alter database test charset $charset collate $collation'."\n";
print '--let $convert_query= `select group_concat(concat("ALTER TABLE ",table_name," CONVERT TO CHARACTER SET ",@@character_set_server," COLLATE ",@@collation_server) SEPARATOR "; ") FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE()`'."\n";
print '--eval $convert_query'."\n";
print "SET GLOBAL event_scheduler= OFF;\n";
print "CREATE USER rqg\@localhost;\n";
print "GRANT ALL ON *.* TO rqg\@localhost;\n";

#foreach my $c ( keys %interesting_connections ) {
#  print "Interesting connection: $c\n";
#}

# The flag will be used if we are only interested in certain connections
my $ignore;
# The flag indicates that Shutdown command appeared in the log (it might be not the latest command
# before actual restart, so we need to keep track of it
my $normal_shutdown= 0;
my $log_rotation_happened= 0;

LOGLINE:
while(<>)
{
  # Log rotation looks like this:
  # /home/elenst/bzr/10.0/sql/mysqld, Version: 10.0.14-MariaDB-debug-log (Source distribution). started with:
  # Tcp port: 19300  Unix socket: /home/elenst/test_results/analyze4/mysql.sock
  # Time                 Id Command    Argument

  # When we see the log rotation records, it means that either
  # - the server was restarted,
  # - or that FLUSH LOGS was executed.
  # To distinguish server restart and FLUSH LOGS, we'll see what happens next.
  # If the next record is Connect with a connection ID which was ever connected before,
  # it means the server was restarted. Otherwise, it means FLUSH LOGS was run.
  # We'll ignore log rotation if we decide it's FLUSH LOGS, because the command itself
  # was somewhere there before, and we've already put it into the test.
  # Server restart is more tricky. It can be either graceful shutdown
  # through Shutdown command (either from the client or from mysqladmin),
  # or SIGTERM (which also causes a graceful shutdown,
  # but without Shutdown command in the log, or SIGKILL.
  # We don't have a way to distinguish SIGTERM from SIGKILL through the general log.
  # For now we'll assume that the SIGx approach is universal through the test --
  # it's either always SIGTERM (e.g. Restart scenario) or always SIGKILL (CrashRestart).
  # We'll use command-line option sigkill to choose. It defaults to 0,
  # which means graceful restart.

  if ($opt_data_location and not $orig_data_location and /\'([^\']+)\'\s+AS\s+DATA_LOCATION/) {
    $orig_data_location= $1;
  } elsif ($orig_data_location and $opt_data_location and s/$orig_data_location/$opt_data_location/g) {};

  if ( /Version:\s+.*\.\s+started with:\s*$/ ) {
    my $l=<>;
    unless ($l =~ /^Tcp\s+port:\s+\d+,?\s+(?:Unix\s+socket|Named\s+Pipe):\s+/si) {
      print STDERR "ERROR: Unexpected line upon log rotation:\n$l";
      exit 1;
    }
    $l=<>;
    unless ($l =~ /^Time\s+Id\s+Command\s+Argument\s*$/s) {
      print STDERR "ERROR: Unexpected line upon log rotation:\n$l";
      exit 1;
    }

    $log_rotation_happened= 1;
    next;
  }

  # 10.4+ writes a warning into the general log, e.g.
  # 6 Connect  Server is running in --secure-auth mode, but 'uu2'@'localhost' has a password in the old format; please change the password to the new format
  # We'll just skip it, there will be a real connect record later
  next if /has a password in the old format; please change the password to the new format/;

  my $new_log_con;
  my $new_log_timestamp;
  my $new_log_record_type;

  # Stripping the timestamp if exists
  if ( s/^(\d{6}\s+\d+:\d\d:\d\d)\s*// )
  {
    $new_log_timestamp= $1;
  }

  # Presence of a connection number and record type
  # means the line is a start of a record

  if ( s/^\s*(\d+)\s+(\w+)// )
  {
    $new_log_con= $1;
    $new_log_record_type= $2;

    # If we have built a previous record (possibly from several lines),
    # now it's time to print it. We'll take into account the $ignore flag there

    print_current_record( $new_log_con );

    if ( $new_log_record_type =~ /Shutdown/ )
    {
      # The actual shutdown/restart will be performed after we see log rotation lines,
      # here we will just keep the marker that it was a normal shutdown through a command
      $normal_shutdown= 1;
      next LOGLINE;
    }

    # If the new record was produced by one of connections we are not interested in,
    # set the flag, but proceed parsing, in case the connection does something
    # important on the system level (like server shutdown)

    $ignore= (scalar(keys %interesting_connections) and not $interesting_connections{$new_log_con}) || $service_connections{$new_log_con};

    if ( $new_log_timestamp )
    {
      # By default we try to make the flow similar to the initial.
      # Since we don't put 'real_sleep', anybody who wants to ignore the delays
      # can later override sleep time from MTR command line

      my $new_log_sec= time_to_sec( $new_log_timestamp );
      $timestamp= $new_log_sec;
      if ( $opt_sleep and $last_log_sec and ( my $dif= ( $new_log_sec - $last_log_sec - 1 ) > 0 ) ) {
        print "--sleep $dif\n";
      }
      $last_log_sec= $new_log_sec;
    }

    # We ignore Prepare, Execute, Statistics and Binlog lines
    next LOGLINE if ( $new_log_record_type =~ /(?:Execute|Binlog|Field|Statistics|Close|Reset)/ );

      # Now we finally process the preserved information about log rotation and possible shutdowns,
      # if there were any, which is indicated by $log_rotation_happened.
      # Further options:
      # - If log_rotation_happened is true, but the next record is NOT Connect, it's a strong indication
      #   (for now) that there was no restart, only FLUSH LOGS. Then we'll just unset the flag and forget about it.
      #   Update: Another case is that the next record is Spider initialization
      #   create table if not exists mysql.spider etc., it happens without Connect record.
      # - If the next record is Connect, it is a weak indication that the restart might have happened.
      #   Then we will check which connection number tries to connect. If it is greater than everything
      #   that was previously used in the current server session, then it's a good enough indication
      #   that it's still the same server, so again, we'll unset the flag and forget about it.
      # - If the connection number is back to smaller values, it means that the server has restarted.
      #   Then we will add include/restart_mysqld.inc.
      #   We still need to determine whether to set a shutdown_timeout or not.
      #   = if normal_shutdown is true, we will set shutdown_timeout.
      #   = otherwise, if opt_sigkill if false, we will still set shutdown timeout.
      #   = otherwise we will set it to 0, which should mean sigkill.

    if ($log_rotation_happened) {
      if ($new_log_record_type eq 'Connect' or /create table if not exists mysql\.spider/) {
        if ($new_log_con > $max_used_connection_id) {
          # The server session continues, so log rotation must be due to FLUSH LOGS
        }
        else {
          # Connection IDs are back to smaller numbers, must be due to server restart
          if ($normal_shutdown or !$opt_sigkill) {
            print "--let \$shutdown_timeout= 30\n";
            $normal_shutdown= 0;
          } else {
            print "--let \$shutdown_timeout= 0\n";
          }
          print "--connection default\n";
          print "--source include/restart_mysqld.inc\n";
          $server_restarts++;
          %test_connections= ();
        }
      }
      else {
        # Next command is not Connect, so log rotation must be due to FLUSH LOGS
      }
      $log_rotation_happened= 0;
    }

    if ( $new_log_record_type eq 'Connect' )
    {
      $max_used_connection_id= $new_log_con;

      next if $_ =~ /Access denied for/;

      # Log record 'Connect' translates into --connect
      # and also changes current connection in the test

      
      my ( $user, $host, $db )= ( $_ =~ /^\s*([^\@]+)\@(\S+)\s(?:as.*?\s)?on\s?(\S*)/ );
      $db= '' unless defined $db;
      my $conname= 'con' . $new_log_con;
      my $password= ( defined $user_passwords{$user.'@'.$host} ? $user_passwords{$user.'@'.$host} : '' );
      if ($user eq 'spider_user' or $user eq 'fed_user' or $user eq 'remote_user') {
        $service_connections{$new_log_con}= 1;
        $ignore= 1;
        next;
      }
      print '--connect ('.$conname.'_'.$server_restarts.",$host,$user,$password,$db)\n";
      print "--enable_reconnect\n";
      print "SET TIMESTAMP= $timestamp /* 1 */;\n" if $opt_timestamps;
      print 'execute immediate concat("set names ",if(@@character_set_server in ("ucs2","utf16","utf32"),"utf8",@@character_set_server));'."\n";
      print "--let \$${conname}_id= `SELECT CONNECTION_ID() AS ${conname}`\n";
      $test_connections{$new_log_con}= 0;
      $cur_test_con= $new_log_con;
    }
    elsif ( $new_log_record_type eq 'Quit' )
    {
      # Log record 'Quit' translates into --disconnect.
      # TODO: There was a problem with disconnect in RQG tool which I had to fix,
      # but I don't remember what it was -- something about losing the current
      # test connection after unfortunate disconnect. Leaving it as is now,
      # but will have to get back to it when the test starts failing

      my $conname= 'con' . $new_log_con;
      if ( $test_connections{$new_log_con} )
      {
        print '--connection '.$conname.'_'.$server_restarts."\n";
        print "--reap\n";
        print "SET TIMESTAMP= $timestamp /* 2 */;\n" if $opt_timestamps;
      }
      if (!$service_connections{$new_log_con}) {
        print "--disconnect ".$conname.'_'.$server_restarts."\n";
      }
      delete $test_connections{$new_log_con};
      delete $service_connections{$new_log_con};
      $cur_test_con= 0;
    }
    elsif ( $new_log_record_type eq 'Change' )
    {
      # Log record 'Change' translates into --change_user
      # and also changes current connection in the test

      my ( $user, $host, $db )= ( $_ =~ /^\s*user\s+(\w+)\@(\S+)\s(?:as.*?\s)?on\s?(\S*)/ );
      $db= '' unless defined $db;
      my $conname= 'con' . $new_log_con;
      print '--connection '.$conname.'_'.$server_restarts."\n";
      print "SET TIMESTAMP= $timestamp /* 3 */;\n" if $opt_timestamps;
      if ( $test_connections{$new_log_con} )
      {
        print "--reap\n";
        $test_connections{$new_log_con}= 0;
      }
      my $password= ( defined $user_passwords{$user.'@'.$host} ? $user_passwords{$user.'@'.$host} : '' );
      print "--change_user $user,$password,$db\n";
      $cur_test_con= $new_log_con;
    }
    elsif ( $new_log_record_type eq 'Query' or $new_log_record_type eq 'Prepare' )
    {
      $cur_log_con= $new_log_con;
      $cur_log_record= $_;
    }
    elsif ( $new_log_record_type eq 'Init' and /\s*DB\s*(.*)/ )
    {
      my $conname= 'con' . $new_log_con;
      my $db_name= $1;
      if ( $test_connections{$new_log_con} )
      {
        print '--connection '.$conname.'_'.$server_restarts."\n";
        print "--reap\n";
        print "SET TIMESTAMP= $timestamp /* 4 */;\n" if $opt_timestamps;
        $test_connections{$new_log_con}= 0;
      }
      $cur_log_con= $new_log_con;
      $cur_log_record= "CREATE DATABASE IF NOT EXISTS $db_name ;\nUSE $db_name;\n";
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
    print "--connection con", $c, '_'.$server_restarts, "\n";
    print "--reap\n";
  }
}
if ($opt_rpl) {
  print "--sync_slave_with_master\n";
} else {
  print "--sleep 6\n";
}
print "--exit\n";

########### SUBROUTINES ############

sub test_hacks
{
  my $log_record_ref= shift;

  # Some frequently occurring syntax error in incoming statements
  if ( $$log_record_ref =~ s/(EXECUTE.*?IMMEDIATE|PREPARE.*?FROM) '[^']*$/$1 '' \//g ) {};
  if ( $$log_record_ref =~ s/^\s*(kill(?:\s+query)?)\s+(\d+)/eval $1 \$con${2}_id/is ) {};
  if ( $$log_record_ref =~ s/^\s*(show.+explain\s+for)\s+(\d+)/eval $1 \$con${2}_id/is ) {};
  # Temporarily disabled due to MDEV-23376
  if ( $$log_record_ref =~ s/(show.*)binlog\s+events/$1 \/\* BINLOG EVENTS replaced \*\/ BINARY LOGS/igs ) {};
  # Remove non-printable (except for tab and new-line)
  $$log_record_ref=~ s/[\x00-\x08\x0B-\x1F]/x/g;
  # Try to fix broken strings without an ending quote and/or bracket and such)
  $$log_record_ref=~ s/(SELECT|EXECUTE.*?IMMEDIATE|PREPARE.*?FROM)\s+\'([^']*)*$/$1 \'$2\'/g;
  $$log_record_ref=~ s/\(\'([^')]*)$/\(\'$1\'\)/g;
  $$log_record_ref=~ s/\(([^)]*)$/\($1\)/g;
  # Mask MTR "special" words, if a query starts from a word
  # like 'if' or 'while', MTR thinks it a flow control expression.
  # But if it's preceeded by a comment, it does not
  if ($$log_record_ref =~ /^\s*(?:IF|WHILE|END)/) {
    $$log_record_ref= '/* */ '.$$log_record_ref;
  }
  # Special 'replication' user is created with password to satisfy password check
  # requirements, but it's not needed here
  $$log_record_ref =~ s/CREATE USER IF NOT EXISTS replication.*$/CREATE USER IF NOT EXISTS replication/;
}

sub time_to_sec
{
  my $ts= shift;
  my ( $year, $month, $day, $hour, $min, $sec )
      = ( $ts =~ /(\d\d)(\d\d)(\d\d)\s+(\d+):(\d\d):(\d\d)/ );

  return timelocal( $sec, $min, $hour, $day, $month-1, $year );
}


sub print_current_record
{
  my $new_log_con= shift;

  # If tables of interest are defined and the command doesn't seem
  # to match the pattern, ignore it
  if ($interesting_tables_pattern and $cur_log_record !~ /$interesting_tables_pattern/s) {
    return;
  }

  # If the query was 'shutdown', don't print it, but prepare
  # for restart_mysqld.inc
  if ( $cur_log_record )
  {
    if ( $cur_log_record =~ /^\s*(?:\/\*.*?\*\/\s*)?shutdown\s*$/i ) {
      $normal_shutdown= 1;
      $cur_log_record= '';
      $cur_log_con= 0;
      return;
    }
    if ($ignore) {
      $ignore= 0;
      $cur_log_record= '';
      $cur_log_con= 0;
      return;
    }
    if ( ! exists( $test_connections{$cur_log_con} ) )
    {
      print '--connect (con'.$cur_log_con.'_'.$server_restarts.',localhost,root,,test)'."\n";
      print "SET TIMESTAMP= $timestamp /* 5 */;\n" if $opt_timestamps;
      print "--let \$con${cur_log_con}_id= `SELECT CONNECTION_ID() AS con${cur_log_con}`\n";
      $test_connections{$cur_log_con}= 0;
      $cur_test_con= $cur_log_con;
    }
    elsif ( $cur_log_con != $cur_test_con ) {
      print '--connection con' . $cur_log_con . '_'.$server_restarts. "\n";
      $cur_test_con= $cur_log_con;
    }

    if ( $test_connections{$cur_log_con} ) {
      print "--reap\n";
      print "SET TIMESTAMP= $timestamp /* 6 */;\n" if $opt_timestamps;
      $test_connections{$cur_log_con}= 0;
    }

    if ($cur_log_record =~ /.*/) {
        chomp $cur_log_record;
        test_hacks(\$cur_log_record);
        if ( $cur_log_record )
        {
          my $delimiter= ( $cur_log_record =~ /;/ ? '|||' : ';' );
          if ( $delimiter eq '|||' ) {
            print "--delimiter |||\n";
          }

          my $need_send= 0;
          if ( $cur_log_con != $new_log_con and !( $cur_log_record =~ /^\s*LOAD DATA/ ) )
          {
            # Whenever log connection changes, we will do --send
            $need_send= "--send\n";
            $test_connections{$cur_log_con}= 1;
          }

          if ($opt_convert_to_ei) {
            my $converted= $cur_log_record;
            $converted =~ s/[^\\]\"/\\\"/g;
            print $need_send if $need_send;
            print 'EXECUTE IMMEDIATE " '.$converted.' "', $delimiter, "\n";
          }
          elsif ($opt_convert_to_ps) {
            my $converted= $cur_log_record;
            $converted =~ s/[^\\]\"/\\\"/g;
            print 'PREPARE converter_stmt FROM " '.$converted.' "', $delimiter, "\n";
            print $need_send if $need_send;
            print "EXECUTE converter_stmt",$delimiter,"\n";
          }
          else {
            print $need_send if $need_send;
            print $cur_log_record, $delimiter, "\n";
          }
          if ( $delimiter ne ';' ) {
            print "--delimiter ;\n";
          }
        }
    }
    if ( $cur_log_record =~ /set\s+password\s+for\s+\'?(\w+)\'?\@\'?(\w+)\'?\s*=\s*password\s*\(\s*\'(\w+)\'\s*\)/ )
    {
      $user_passwords{$1.'@'.$2}= $3;
    }

    $cur_log_record= '';
    # The next is not necessary, but it might make debugging easier
    $cur_log_con= 0;
  }
}

