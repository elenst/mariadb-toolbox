use POSIX ":sys_wait_h";
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use File::Copy "copy";
use File::Path qw(make_path remove_tree);
use List::Util qw(min max);

use strict;

my $opt_mode = 'all';
my $output;
my $suitedir = 't';
my $suitename;
my @options = '';
my $testcase;
my $path = dirname(abs_path($0));
my $opt_preserve_connections;
my $rpl= undef;
my $max_chunk= 0;
my $vardir='var';
$|= 1;

# $trials is the number of attempts for every intermediate test case.
# It cannot be done via MTR --repeat, because we need it not just fail
# (and not necessarily fail), but produce a specific outcome.
# The number of trials will be to some extent dynamic: if the test case
# timed out (and the current timeout is high enough, currently >= 30 min),
# the number of trials will be temporarily reduced to 2.
my $trials= 1;

# $initial_trials is the number of attempts for the very attempt
# for the unchanged test case produced from the original general log.
# It is more important than consequent runs, because the outcome defines
# whether simplification job will proceed or not. So, unless configured
# explicitly, it will be set to $trials * 3
# The number of trials will be to some extent dynamic: if the test case
# timed out (and the current timeout is high enough, currently >= 30 min),
# the number of trials will be temporarily reduced to 3.
my $initial_trials= undef;

# Timeout is used by a watchdog for every separate test run.
# Normally this job is done by MTR via testcase-timeout, but sometimes
# after certain failures it tends to hang (e.g. it happens often after stack overflow).
# It is also useful when you want timeout less than 2 minutes, because
# it is de-facto minimum in MTR.
# In this case the simplifier will kill it after $timeout is exceeded
# Since the maximum testcase-timeout in MTR is 5 hours, we'll set ours to 6 hours.
# The actual timeout will be dynamic, based on the duration of previous
# test runs. But it will never be *higher* than the configured --timeout
# (which is stored in $max_timeout).
# $testcase_timeout is what will be passed to MTR. If not defined
# in @options, it will be set 2 minutes less than $timeout
my $max_timeout= 21600;
my $timeout;
my $testcase_timeout;

# $simplification_timeout is a limit for the whole simplification job.
# When the timeout is approached, the job will store whatever best result it had.
# It is useful when it is run in a time-limited environment.
my $simplification_timeout= 0;

my @preserve_connections;
my %preserve_connections;

my @modes;

$|= 1;

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
  "options=s@"   => \@options,
  "rpl=s"       => \$rpl,
  "preserve-connections|preserve_connections=s" => \$opt_preserve_connections,
  "max-chunk-size|max_chunk_size=i" => \$max_chunk,
  "trials=i"    => \$trials,
  "initial-trials|initial_trials=i"    => \$initial_trials,
  "test-timeout|test_timeout=i"   => \$timeout,
  "simplification-timeout|simplification_timeout=i"   => \$simplification_timeout,
);

my $endtime= ($simplification_timeout ? time() + $simplification_timeout : 0);

my $max_trial_duration= 0;
$initial_trials = $trials * 3 unless defined $initial_trials;

if (!$testcase) {
  print "ERROR: testcase is not defined\n";
  exit 1;
}

if (lc($opt_mode) eq 'all') {
  @modes= ('conn','stmt','line','sql');
} elsif ($opt_mode =~ /^(stmt|line|conn|sql)/i) {
  @modes= lc($1);
} else {
  print "ERROR: Unknown simplification mode: $opt_mode. Only 'stmt', 'line', 'conn', 'sql', 'all' are allowed\n";
  exit 1;
}

if ($opt_preserve_connections) {
  @preserve_connections = split /,/, $opt_preserve_connections;
  foreach ( @preserve_connections ) { $preserve_connections{$_} = 1 };
}

if ("@options" =~ /--vardir=(\S+)/) {
    $vardir=$1;
}

if ("@options" =~ /.*--testcase-timeout=(\d+)/) {
    $testcase_timeout = $1;
}

if (defined $timeout) {
    $max_timeout= $timeout;
} elsif ($testcase_timeout) {
    $max_timeout= $timeout= $testcase_timeout * 60 + 60;
} else {
    $timeout= $max_timeout;
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

if ($output) {
  $output= qr/$output/s;
  print "\nPattern to search: $output\n";
}

my $test_basename= ($rpl ? 'new_rpl' : 'new_test');

if ($ENV{MTR_VERSION} eq "1" and ($suitename eq 't' or $suitename eq 'main') and not -e "r/$test_basename.result") {
  system("touch r/$test_basename.result");
}

copy("$suitedir/$testcase.test","$suitedir/$test_basename.test") || die "Could not copy $suitedir/$testcase.test to $suitedir/$test_basename.test";

my $reproducible_counter = 0;
my $not_reproducible_counter = 0;

remove_tree("$testcase.output");
make_path("$testcase.output");

my ($test, $big_connections, $small_connections) = read_testfile("$suitedir/$test_basename.test",$modes[0]);

print "\nRunning initial test\n";

my $trials_save= $trials;
# The intial test run is most important, we'll try it more before giving up
$trials= $initial_trials;

unless (run_test($test))
{
  print "The initial test didn't fail!\n\n";
  exit 1;
}
$trials= $trials_save;

my @last_failed_test= @$test;

foreach my $mode (@modes)
{
  print "\n\n====== mode: ".uc($mode)." ========\n";

  if ($mode eq 'conn')
  {
    # Connection mode is always first, no need to re-read the test file

    print "\nTotal number of big connections: " . scalar(@$big_connections) . ", small connections: " . scalar(@$small_connections) . "\n\n";

    check_connections_one_by_one(@$big_connections);

    if (scalar @$small_connections) {
      print "Trying to get rid of all small connections at once: @$small_connections\n";

      my %cons = map { $_ => 1 } @$small_connections;
      my @new_test = ();
      my $skip= 0;
      foreach my $t (@last_failed_test) {
        if ( $t =~ /^\s*\-\-(?:connect\s*\(\s*|disconnect\s+|connection|source\s+)([^\s\,]+)/s )
        {
          $skip = ( exists $cons{$1} );
          #print STDERR "COnnection $1 - in hash? $connections{$1}; ignore? $ignore\n";
        }
        push @new_test, $t unless $skip;
      }
      if (run_test(\@new_test)) {
        print "Small connections are not needed\n\n";
        @last_failed_test= @new_test;
      } elsif (scalar(@$small_connections) == 1) {
        print "There is only one small connection, and it's needed\n\n";
      } else {
        print "Some of small connections are needed, have to check them one by one\n\n";
        check_connections_one_by_one(@$small_connections);
      }
    }
  }

  elsif ($mode eq 'stmt' or $mode eq 'line')
  {
    # Re-read the test in the new mode
    write_testfile(\@last_failed_test);
    # We don't need connections (second returned value) anymore
    ($test, undef)= read_testfile("$suitedir/$test_basename.test",$mode);

    my @test= @$test;
    if (scalar(@test) <= 1) {
      exit;
    }

    # We are setting initial chunk size to 1/10th of the test size
    # If a limitation on chunk size was provided as an option,
    # it is applied on top of it
    my $max_chunk_size= $max_chunk || int(scalar(@test)/10);
    my $chunk_size= max(1, min($max_chunk_size,int(scalar(@test)/10)));

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
          if ( $l =~ /\#\s+PRESERVE/i or $l =~ /^\s*(?:if|while|{|}|--let|--dec|--inc|--eval|--enable_abort_on_error|--disable_abort_on_error|--sync_slave_with_master|--exec|--cat_file|--error|--source\s+include\/master-slave\.inc|--source\s+include\/have_binlog_format.*\.inc)/ )
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
  elsif ($mode eq 'sql') {
    # Re-read the test in the new mode
    write_testfile(\@last_failed_test);
    # We don't need connections (second returned value) anymore, and we need statements, not lines
    ($test, undef)= read_testfile("$suitedir/$test_basename.test",'stmt');

    my @test= @$test;
    if (scalar(@test) <= 1) {
      exit;
    }

    # Clauses we are currently able to process:
    # - LIMIT n : try to remove
    # - OFFSET n : try to remove
    # - LOW_PRIORITY : try to remove
    # - QUICK - try to remove
    # - ORDER BY <list of fields> : try to remove
    # - SELECT <list of fields> : try to replace with SELECT *

    my %patterns= (
      qr/LIMIT\s+\d+/ => '',
      qr/OFFSET\s+\d+/ => '',
      qr/\sLOW_PRIORITY/ => '',
      qr/\sQUICK/ => '',
      qr/ORDER\s+BY\s+[\w\`,]+/ => '',
      qr/LEFT\s+JOIN/ => 'JOIN',
      qr/RIGHT\s+JOIN/ => 'JOIN',
      qr/NATURAL\s+JOIN/ => 'JOIN',
      qr/SELECT\s+[\w\`,\.]?\s+FROM/ => 'SELECT * FROM',
      qr/PARTITION\s+BY\s+.*?\s+PARTITIONS\s+\d+/ => '',
      qr/\/\*[^\!].*?\*\// => '',
      qr/OR\s+REPLACE/ => '',
      qr/ROW_FORMAT\s*=?\s*\w+/ => '',
      qr/INVISIBLE/ => '',
      qr/COMPRESSED/ => '',
      qr/\`/ => '',
    );

    foreach my $p (keys %patterns) {
      print "\n\nNew replacement: $p => $patterns{$p}\n";

      my $count= 0;
      my @new_test= ();
      foreach my $s (@test) {
        if (my $n = ($s =~ s/$p/$patterns{$p}/isg)) {
          $count+= $n;
        }
        push @new_test, $s;
      }

      if ($count) {
        print "Found $count occurrences of the pattern\n";
        if ( run_test( \@new_test ) )
        {
          @test= @new_test;
          print "Clause $p has been replaced with $patterns{$p}\n";
        }
        else {
          print "Keeping clause $p\n";
        }
      }
      else {
        print "Haven't found any occurrences of the pattern\n";
      }
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
  
  if ($endtime and ( time() + $max_trial_duration > $endtime )) {
    print "Only " . ($endtime - time()) . " seconds left till simplification timeout, while the longest trial took $max_trial_duration seconds. Quitting with what we have\n";
    exit 2;
  }
  print "\nSize of the test to run: " . scalar(@$testref) . "\n";

  write_testfile($testref);

  my $result= undef;

  my $i= 1;
  while ($i <= $trials) {
    my $start = time();
    print sprintf("Trial $i out if $trials started at %02d:%02d:%02d\n",(localtime($start))[2],(localtime($start))[1],(localtime($start))[0]);
    $testcase_timeout= min(max(int(($timeout-15)/60),1),300);

    my $test_result;
    my $pid= fork();

    if ($pid) {
      foreach (1..$timeout) {
        waitpid($pid, WNOHANG);
        if ($? > -1) {
          $test_result= $?;
          last;
        }
        sleep 1;
      }
      unless (defined $result) {
        print "The trial timed out\n";
        kill '-KILL', $pid;
        $test_result= 1;
        $result= 0;
      }
    }
    elsif (defined $pid) {
      # Leave 15 seconds for killing
      print "Trial timeout: $timeout sec, testcase timeout: $testcase_timeout min\n\n";

      system( "perl mysql-test-run.pl @options --suite=$suitename $test_basename --testcase-timeout=$testcase_timeout > $testcase.output/$testcase.out.last 2>&1" );
      exit $? >> 8;
    } else {
      print "ERROR: Could not fork for running the test\n";
      exit 1;
    }

    my $out= readpipe("cat $testcase.output/$testcase.out.last");
    my $errlog = ( $ENV{MTR_VERSION} eq "1" ? "$vardir/log/master.err" : "$vardir/log/mysqld.1.err");

    my $separ= $/;
    $/= undef;
    unless (open(ERRLOG, "$errlog")) {
        print "ERROR: Cannot open $errlog\n";
        exit 1;
    }
    $out.= <ERRLOG>;
    close(ERRLOG);
    if (-e "$vardir/log/mysqld.2.err") {
      open(ERRLOG, "$vardir/log/mysqld.2.err") || print "Cannot open $vardir/log/mysqld.2.err\n" && exit 0;
      $out.= <ERRLOG>;
      close(ERRLOG);
    }
    $/= $separ;

    my $trial_duration= time() - $start;
    $max_trial_duration= $trial_duration if $trial_duration > $max_trial_duration;

    # Refined diagnostics
    if ($output) {
      $result= ( $out =~ /$output/ );
      if ($result) {
        print "Reproduced (no: $reproducible_counter) - output matched the pattern\n";
      } elsif ($test_result) {
        print "Could not reproduce - trial $i failed, but output didn't match the pattern\n";
      } else {
        print "Could not reproduce - trial $i passed, and output didn't match the pattern\n";
      }
    }
    elsif ($test_result) {
      $result= $test_result;
      print "Reproduced (no: $reproducible_counter) - test failed, and there was no pattern to match\n";
    }
    else {
      print "Could not reproduce - test passed, and there was no pattern to match\n";
    }

    print "Trial $i time: $trial_duration\n";

    my $outfile;
    if ($result) {
        $outfile= "$testcase.output/$testcase.out.reproducible.$reproducible_counter";
        $timeout= min($timeout, $trial_duration*2);
        print "Timeout is now set to $timeout sec\n";
    } else {
        $outfile= "$testcase.output/$testcase.out.not_reproducible.$not_reproducible_counter";
        if ($trial_duration > $testcase_timeout and $testcase_timeout >= 30 and $i < $trials - 1) {
            print "\nTest run took longer than testcase timeout $testcase_timeout min, trying only one more more\n\n";
            $trials= $i + 1;
        }
    }
    $i++;
    open( OUT, ">>$outfile" ) || die "Could not open $outfile for writing: $!";
    print OUT "\nTrial $i\n\n";
    print OUT $out;
    close( OUT );

    if ($result)
    {
      copy("$suitedir/$test_basename.test", "$suitedir/$testcase.test.reproducible.$reproducible_counter") || die "Could not copy $suitedir/$test_basename.test to $suitedir/$testcase.test.reproducible.$reproducible_counter: $!";
      last;
    }
  }

  ($result ? $reproducible_counter++ : $not_reproducible_counter++);
  return $result;
}

sub write_testfile
{
  my $testref= shift;
  open( TEST, ">$suitedir/$test_basename.tmp" ) or die "Could not open $suitedir/$test_basename.tmp for writing: $!";
  print TEST "--disable_abort_on_error\n";
  if ($rpl) {
    print TEST "--source include/master-slave.inc\n";
    print TEST "--source include/have_binlog_format_".$rpl.".inc\n";
  }
  print TEST @$testref;
  if ($rpl) {
    print TEST "\n--connection master\n--sync_slave_with_master\n";
  }
  close( TEST );
  system("perl $path/cleanup_sends_reaps.pl $suitedir/$test_basename.tmp > $suitedir/$test_basename.test");
  # In some cases cleanup makes the test stop failing (on whatever reason).
  # Then I comment the line above and uncomment the line below
  #system("cp $suitedir/$test_basename.tmp $suitedir/$test_basename.test");
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
#    if ( /include\/master-slave\.inc/s or /sync*_with_master/s )
#    {
#      # If replication is needed, it will be added separately
#      next;
#    }
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


  my @big_connections= ();
  my @small_connections= ();
  my $small_connection_threshold= 8;

  # Only bother to sort connections by usage if operate in connection mode
  if ($mode eq 'conn') {
    # Make sure that values are unique, so that we can invert the hash safely
    foreach my $k (keys %connections) {
      $k =~ /con(\d+)/;
      $connections{$k}+= $1/1000;
    }
    my %lengths= reverse %connections;
    foreach my $k (reverse sort {$a<=>$b} keys %lengths) {
      $k > $small_connection_threshold ? push @big_connections, $lengths{$k} : push @small_connections, $lengths{$k};
    }
  }

  return (\@test, \@big_connections, \@small_connections);
}


sub check_connections_one_by_one {

  my $skip= 0;
  my $counter= 0;

  foreach my $c (@_)
  {
    print "Checking connection $c (" . (++$counter) . " out of " . scalar(@_) . ")\n";

    if ($preserve_connections{$c}) {
      print "\nPreserving connection $c\n";
      next;
    }

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
      print "Connection $c is not needed\n\n";
      @last_failed_test= @new_test;
    } else {
      print "Saving connection $c\n\n";
    }
  }

}
