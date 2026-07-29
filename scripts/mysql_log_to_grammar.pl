use Time::Local;
use Getopt::Long;
use strict;

my @rules;

my $opt_data_location_substitute= '';
my $opt_suite= '';

GetOptions (
  "data-location|data_location=s" => \$opt_data_location_substitute,
  "suite=s" => \$opt_suite,
);

my $cur_con= undef;
my $orig_data_location= '';
my $cur_log_record= '';
my %open_connections= ();

LOGLINE:
while(my $line = <>)
{
  if ($opt_data_location_substitute and not $orig_data_location and ($line =~ /\'([^\']+)\'\s+AS\s+DATA_LOCATION/)) {
    $orig_data_location= $1;
  } elsif ($orig_data_location and $opt_data_location_substitute and ($line =~ s/$orig_data_location/$opt_data_location_substitute/g)) {};

  # 10.4+ writes a warning into the general log, e.g.
  # 6 Connect  Server is running in --secure-auth mode, but 'uu2'@'localhost' has a password in the old format; please change the password to the new format
  # We'll just skip it, there will be a real connect record later
  next if $line =~ /has a password in the old format; please change the password to the new format/;

  next if $line =~ /call mtr\.(?:check_testcase|add_suppression)/;
  next if $line =~ /^\s*\#/;

  # Log rotation looks like this:
  # /home/elenst/bzr/10.0/sql/mysqld, Version: 10.0.14-MariaDB-debug-log (Source distribution). started with:
  next if $line =~ /Version:\s+.*\.\s+started with:\s*/;
  next if $line =~ /^Tcp port:\s+\d+\s+Unix socket/;
  next if $line =~ /^Time\s+Id\s+Command\s+Argument\s*/;
  next if $line =~ /^\s*$/;
  # Skip debug variables for now
  next if $line =~ /debug_dbug|debug_sync|innodb_\w*debug/i && $line =~ /set\s+/i;

  $line =~ s/\|/ \{ chr\(124\) \} /g;

  my $new_con;
  my $new_log_record_type;

  # Stripping the timestamp if exists
  $line =~ s/^(\d{6}\s+\d+:\d\d:\d\d)/\t/;

  while ($line =~ s/;\s*\n/\n    ;/g) {};

  # Presence of a connection number and record type
  # means the line is a start of a record
  if ( $line =~ s/^\t\t\s+(\d+)\s+(\w+)// )
  {
    $new_con= $1;
    $new_log_record_type= $2;

    # If we have built a previous record (possibly from several lines),
    # now it's time to store it

    if (defined $cur_con && $cur_log_record) {
      push @{$open_connections{$cur_con}}, $cur_log_record;
      $cur_log_record= '';
    }

    # We ignore certain types
    # TODO:
    # - deal with Change (user)
    # - Long stands for Long Data. What is that?!
    # - Refresh?
    next LOGLINE if ( $new_log_record_type =~ /(?:Execute|Binlog|Field|Statistics|Close|Reset|Shutdown|Refresh|Long|Change)/ );

    if ( $new_log_record_type eq 'Connect' )
    {
      # If we already had contents for the same connection ID, likely
      # the server was restarted since then. We should store it
      # as a finished rule and start anew

      if ($open_connections{$new_con} && scalar(@{$open_connections{$new_con}})) {
        push @rules, [ @{$open_connections{$new_con}} ];
      }
      # "# connection $new_con\n"
      $open_connections{$new_con}= [];

      next if $line =~ /Access denied for/;

      if ($line =~ /^\s*(?:[^\@]+)\@(?:\S+)\s(?:as.*?\s)?on\s(\S+)/) {
        push @{$open_connections{$new_con}}, "USE $1\n";
      }
    }
    elsif ( $new_log_record_type eq 'Quit' )
    {
      if ($open_connections{$new_con} && scalar(@{$open_connections{$new_con}})) {
        push @rules, [ @{$open_connections{$new_con}} ];
      }
      delete $open_connections{$new_con};
    }
    elsif ( $new_log_record_type eq 'Query' or $new_log_record_type eq 'Prepare' )
    {
      $cur_con= $new_con;
      $cur_log_record= $line;
    }
    elsif ( $new_log_record_type eq 'Init' and ($line =~ /\s*DB\s*(.*)/))
    {
      my $db_name= $1;
      push @{$open_connections{$new_con}}, "CREATE DATABASE IF NOT EXISTS `$db_name`\n";
      push @{$open_connections{$new_con}}, "USE `$db_name`\n";
    }
    else {
      print "ERROR: Unknown record type: $new_log_record_type in $line\n";
      exit 1;
    }
  }
  elsif ( $cur_log_record ) {
    if ($line =~ /\s*30\s+Query\s+select\s+\@result\s=\s0/) {
      print "Line: \n$line\n";
      print "Cur record: \n$cur_log_record\n";
      system("echo '$line' > t");
      system("hexdump -C t");
      die;
    }

    $cur_log_record .= ' ' . $line;
  }
  else {
    # This is something else, for example start records in the log. Can print it here
    # for investigation purposes
    # print "HERE: Something else:\n$line";
  }
}

# Last record
push @{$open_connections{$cur_con}}, $cur_log_record;

foreach my $c (keys %open_connections) {
  if ($open_connections{$c} && scalar(@{$open_connections{$c}})) {
    push @rules, [ @{$open_connections{$c}} ];
  }
}

print "# Number of rules: ".(scalar(@rules))."\n\n";


my $rule_id= 0;
my @rule_names= ();
foreach my $r (@rules) {
  $rule_id++;
  my $rn= sprintf("mtr_${opt_suite}_rule_%05d",$rule_id);
  push @rule_names, $rn;
  print "$rn:\n";
  print "    ",(join "    ;", @$r),";\n\n";
}

print "\nquery_add:\n      ";
print join "\n    | ", @rule_names;
print "\n;\n";

########### SUBROUTINES ############

sub test_hacks
{
  my $log_record_ref= shift;

  # Some frequently occurring syntax error in incoming statements
  if ( $$log_record_ref =~ s/(IMMEDIATE|FROM) ' \//$1 '' \//g ) {};
  if ( $$log_record_ref =~ s/(IMMEDIATE|FROM) '\s*$/$1 ''/g ) {};
  if ( $$log_record_ref =~ s/^\s*(kill(?:\s+query)?)\s+(\d+)/eval $1 \$con${2}_id/is ) {};
  if ( $$log_record_ref =~ s/^\s*(show.+explain\s+for)\s+(\d+)/eval $1 \$con${2}_id/is ) {};
  # Temporarily disabled due to MDEV-23376
  if ( $$log_record_ref =~ s/(show.*)binlog\s+events/$1 \/\* BINLOG EVENTS replaced \*\/ BINARY LOGS/igs ) {};
}

