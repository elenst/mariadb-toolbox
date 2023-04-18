#!/usr/bin/perl

# Copyright (c) 2014, 2020, Elena Stepanova and MariaDB
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

use POSIX ":sys_wait_h";
use Getopt::Long;
use Cwd qw(abs_path cwd);
use File::Basename;
use File::Copy "copy";
use File::Path qw(make_path remove_tree);
use List::Util qw(min max);

use strict;

my $opt_mode = 'all';
my @output;
my $suitedir = 't';
my $suitename;
my @options;
my $testcase;
my $path = dirname(abs_path($0));
my $opt_preserve_connections;
my $rpl= undef;
my $max_chunk= 0;
my $vardir='var';
my $with_minio= 0;
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
# Since the maximum testcase-timeout in MTR is 5 hours, we'll set our
# hard default to 6 hours.
# If the timeout is provided via --test-timeout option, it will be fixed
# for the duration of the simplification. Otherwise it will be dynamic,
# starting with max_timeout and further based on the duration of previous
# test runs. But it will never be *higher* than the default max_timeout
# and *lower* than the default min_timeout.
# $testcase_timeout is what will be passed to MTR. If not defined
# in @options, it will be set 2 minutes less than $timeout
my $max_timeout= 21600;
my $min_timeout= 300;
my $timeout;
my $testcase_timeout;

# $simplification_timeout is a limit for the whole simplification job.
# When the timeout is approached, the job will store whatever best result it had.
# It is useful when it is run in a time-limited environment.
my $simplification_timeout= 0;

my %preserve_connections;
my $preserve_pattern;

my @modes;

my $max_trial_duration= 0;
my $reproducible_counter = 0;
my $not_reproducible_counter = 0;
my $endtime= 0;

$|= 1;

if ($^O eq 'MSWin32' or $^O eq 'MSWin64') {
  require Win32::API;
  my $errfunc = Win32::API->new('kernel32', 'SetErrorMode', 'I', 'I');
  my $initial_mode = $errfunc->Call(2);
  $errfunc->Call($initial_mode | 2);
}

####################
# Option processing
####################

GetOptions (
  "testcase=s"  => \$testcase,
  "mode=s"      => \$opt_mode,
  "output=s@"    => \@output,
  "suitedir=s"  => \$suitedir,
  "suite=s"     => \$suitename,
  "options=s@"   => \@options,
  "rpl=s"       => \$rpl,
  "preserve-connections|preserve_connections=s" => \$opt_preserve_connections,
  "preserve-query|preserve_query=s" => \$preserve_pattern,
  "max-chunk-size|max_chunk_size=i" => \$max_chunk,
  "trials=i"    => \$trials,
  "initial-trials|initial_trials=i"    => \$initial_trials,
  "test-timeout|test_timeout=i"   => \$timeout,
  "simplification-timeout|simplification_timeout=i"   => \$simplification_timeout,
  "minio!"      => \$with_minio,
);

if (!$testcase) {
  print "ERROR: testcase is not defined\n";
  exit 1;
}

if (lc($opt_mode) eq 'all') {
  @modes= ('conn','stmt','line','syntax','options','cleanup');
} elsif ($opt_mode =~ /^(stmt|line|conn|syntax|options|cleanup)/i) {
  @modes= lc($1);
} else {
  print "ERROR: Unknown simplification mode: $opt_mode. Only 'stmt', 'line', 'conn', 'syntax', 'options', 'cleanup', 'all' are allowed\n";
  exit 1;
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

if (not defined $initial_trials) {
  $initial_trials= $trials;
}

if ($simplification_timeout) {
  $endtime= time() + $simplification_timeout;
}

if ($opt_preserve_connections) {
  my @pc = split /,/, $opt_preserve_connections;
  foreach ( @pc ) { $preserve_connections{$_} = 1 };
}

if ("@options" =~ /--vardir=(\S+)/) {
    $vardir=$1;
}

if ("@options" =~ /.*--testcase-timeout=(\d+)/) {
    $testcase_timeout = $1;
}

if ("@options" =~ /s3/) {
  $with_minio= 1;
}

# Parse options and make adjustments

my $max_prepared_stmt_count;
my $enforce_storage_engine;

my @opts= ();
foreach my $o (@options) {
  my @o= split / /, $o;

  # max-prepared-stmt-count=0 doesn't allow server to re-bootstrap if needed.
  # We can't override it completely, because it can have significant effect
  # on test execution; so, we'll change it on the command line,
  # but will add as a global dynamic variable instead
  foreach my $i (0..$#o) {
    if ($o[$i] =~ /^--mysqld=--max[-_]prepared[-_]stmt[-_]count=(\d+)/) {
      $max_prepared_stmt_count= $1;
      delete $o[$i];
  # enforce-storage-engine does not allow server to re-bootstrap if needed
    } elsif ($o[$i] =~ /^--mysqld=--enforce[-_]storage[-_]engine=(\w+)/) {
      $enforce_storage_engine= $1;
      delete $o[$i];
    }
  }
  push @opts, @o;
}

# If the eventual value of the option is greater than zero,
# we can use it on the command line and be done with it.
# Otherwise, if it's exactly zero, it will have to be handled later.
if ($max_prepared_stmt_count) {
  push @opts, "--mysqld=--max-prepared-stmt-count=$max_prepared_stmt_count";
  undef $max_prepared_stmt_count;
}

# password check is unlikely to have any value (for now, at least),
# so we'll disable it
push @opts, '--mysqld=--loose-simple-password-check=off';


@options= @opts;


if (defined $timeout) {
    $max_timeout= $timeout;
    $min_timeout= $timeout;
} elsif ($testcase_timeout) {
    $max_timeout= $timeout= my_max($testcase_timeout * 60 + 60,$min_timeout);
} else {
    $timeout= $max_timeout;
}

if (scalar @output) {
  print "\nPatterns to search (all should be present): @output\n";
}
$preserve_pattern= ($preserve_pattern ? "$preserve_pattern|\#\s+PRESERVE|mariabackup" : "\#\s+PRESERVE|mariabackup");
print "Patterns to preserve: $preserve_pattern\n";

my $test_basename= ($rpl ? 'new_rpl' : 'new_test');

if ($ENV{MTR_VERSION} eq "1" and ($suitename eq 't' or $suitename eq 'main') and not -e "r/$test_basename.result") {
  system("touch r/$test_basename.result");
}

####################
# Files
####################

print "Initial test case: $suitedir/$testcase.test\n";
print "Basedir: ".dirname(abs_path(cwd()))."\n";
print "Vardir: $vardir\n";

unlink("$suitedir/$test_basename.test");
if (defined $max_prepared_stmt_count and $max_prepared_stmt_count == 0) {
  system("echo \"SET GLOBAL max_prepared_stmt_count=0;\" >> $suitedir/$test_basename.test");
  die "Could not write into $suitedir/$test_basename.test: $!" if $?;
}
if (defined $enforce_storage_engine) {
  system("echo \"SET GLOBAL enforce_storage_engine=$enforce_storage_engine;\" >> $suitedir/$test_basename.test");
  die "Could not write into $suitedir/$test_basename.test: $!" if $?;
}
system("cat $suitedir/$testcase.test >> $suitedir/$test_basename.test");
die "Could not cat $suitedir/$testcase.test into $suitedir/$test_basename.test" if $?;
#copy("$suitedir/$testcase.test","$suitedir/$test_basename.test") || die "Could not copy $suitedir/$testcase.test to $suitedir/$test_basename.test";

remove_tree("$testcase.output");
make_path("$testcase.output");

####################
# Initial trials
####################

my ($test, $big_connections, $small_connections) = read_testfile("$suitedir/$test_basename.test",$modes[0]);

my $trials_save= $trials;
$trials= $initial_trials;

print "\n\n====== Initial test ========\n";

print "\nFirst round, quick: zero timeouts and minimal sleep time\n\n";
my @options_save= @options;
push @options, '--sleep=1', '--mysqld=--lock-wait-timeout=0', '--mysqld=--loose-innodb-lock-wait-timeout=0', "--mysqld=--secure-file-priv=''";
if (run_test($test))
{
  print "Quick run succeeded, keeping minimal timeouts\n";
} else {
  @options= @options_save;
  print "\nSecond round, full timing\n\n";
  unless (run_test($test)) {
    print "The initial test didn't fail!\n\n";
    exit 1;
  }
}
my @last_failed_test= @$test;
$ trials= $trials_save;

####################
# Simplification
####################

foreach my $mode (@modes)
{
  print "\n\n====== mode: ".uc($mode)." ========\n";

  if ($mode eq 'conn')
  {
    # Connection mode is always first, no need to re-read the test file

    print "\nTotal number of big connections: " . scalar(@$big_connections) . ", small connections: " . scalar(@$small_connections) . "\n\n";

    while (check_connections_one_by_one(@$big_connections)) {
      write_testfile(\@last_failed_test);
      ($test, $big_connections, $small_connections) = read_testfile("$suitedir/$test_basename.test",$mode);
      my @test= @$test;
      if (scalar(@test) <= 1) {
        exit;
      }
    }

    if (scalar @$small_connections) {
      print "Trying to get rid of all small connections at once: @$small_connections\n";

      my %cons = map { $_ => 1 } @$small_connections;
      my @new_test = ();
      my $skip= 0;
      foreach my $t (@last_failed_test) {
        if ( $t =~ /^\s*\-\-(?:connect\s*\(\s*|disconnect\s+|connection)([^\s\,]+)/s )
        {
          $skip = ( exists $cons{$1} );
          #print STDERR "COnnection $1 - in hash? $connections{$1}; ignore? $ignore\n";
        }
        push @new_test, $t unless $skip;
      }
      if (run_test(\@new_test)) {
        print "Small connections are not needed\n\n";
        @last_failed_test= @new_test;
#      } elsif (scalar(@$small_connections) == 1) {
#        print "There is only one small connection, and it's needed\n\n";
      } else {
        print "Some of small connections are needed, preserving them for now\n\n";
#        print "Some of small connections are needed, have to check them one by one\n\n";
#        check_connections_one_by_one(@$small_connections);
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

    # We are setting initial chunk size to 1/3rd of the test size
    # If a limitation on chunk size was provided as an option,
    # it is applied on top of it
    my $max_chunk_size= $max_chunk || int(scalar(@test)/3);
    my $chunk_size= my_max(1, my_min($max_chunk_size,int(scalar(@test)/3)));

    my @needed_part = @test;

    while ( $chunk_size > 0 )
    {
      print "\n\nNew chunk size: $chunk_size\n";
      my $progress_made;
      do {
        @test = @needed_part;
        @needed_part = ();
        my $next_unchecked = 0;
        $progress_made= 0;

        while ( $next_unchecked <= $#test )
        {
          my @chunk= ();
          my @preserved_part = ();
          my $end_of_chunk;

          for (my $i=$next_unchecked; $i <= $#test; $i++) {
            my $l= $test[$i];
            $end_of_chunk= $i;
            if ( $l =~ /$preserve_pattern/ or ($mode eq 'stmt' and $l =~ /^\s*(?:if|while|{|}|--.*)/ ))
            {
              push @preserved_part, $l;
            }
            push @chunk, $l;
            last if scalar(@chunk)-scalar(@preserved_part) >= $chunk_size;
          }
            my @new_test = ( @needed_part, @preserved_part, @test[$end_of_chunk+1..$#test] );

            if (scalar(@chunk) <= scalar(@preserved_part)) {
              print "Whole chunk [$next_unchecked .. $end_of_chunk] $mode(s) is preserved\n";
              push @needed_part, @chunk;
            }
            else {
              print "\nNext range: [$next_unchecked .. $end_of_chunk] $mode(s) out of ".scalar(@test).(scalar(@preserved_part) ? ', '.scalar(@preserved_part)." $mode(s) preserved" : "")."\n";
              if ( run_test( \@new_test ) )
              {
                $progress_made= 1;
                @last_failed_test= @new_test;
                print "Chunk $next_unchecked .. $end_of_chunk is not needed".(scalar(@preserved_part) ? ", but preserving ".scalar(@preserved_part)." $mode(s)" : "")."\n";
                push @needed_part, @preserved_part;
              }
              else {
                print "Saving chunk $next_unchecked .. $end_of_chunk\n";
                push @needed_part, @chunk;
              }
            }
          $next_unchecked = $end_of_chunk+1;
        }
        if ($progress_made) {
          print "\n\nProgress has been made with chunk size $chunk_size, repeating the cycle\n";
        }
      } while ($progress_made);
      $chunk_size = int( $chunk_size/2 );
    }
  }
  elsif ($mode eq 'syntax') {
    # Re-read the test in the new mode
    write_testfile(\@last_failed_test);
    # We don't need connections (second returned value) anymore, and we need statements, not lines
    ($test, undef)= read_testfile("$suitedir/$test_basename.test",'stmt');

    my @test= @$test;
    if (scalar(@test) <= 1) {
      exit;
    }

    my @patterns= (
      [ qr/LIMIT\s+\d+/, '' ],
      [ qr/OFFSET\s+\d+/, '' ],
      [ qr/\sLOW_PRIORITY/, '' ],
      [ qr/\sQUICK/, '' ],
      [ qr/ORDER\s+BY\s+[\w\`,]+/, '' ],
      [ qr/LEFT\s+JOIN/, 'JOIN' ],
      [ qr/RIGHT\s+JOIN/, 'JOIN' ],
      [ qr/NATURAL\s+JOIN/, 'JOIN' ],
      [ qr/SELECT\s+[\w\`,\.]?\s+FROM/, 'SELECT * FROM' ],
      [ qr/PARTITION\s+BY\s+.*?\s+PARTITIONS\s+\d+/, '' ],
      [ qr/\/\*[^\!].*?\*\//, '' ],
      [ qr/OR\s+REPLACE/, '' ],
      [ qr/ROW_FORMAT\s*=?\s*\w+/, '' ],
      [ qr/INVISIBLE/, '' ],
      [ qr/COMPRESSED/, '' ],
      [ qr/ENGINE\s*=\s*\w+/, '' ],
      [ qr/\`/, '' ],
      [ qr/^\s*--let\s.*/, '' ],
      [ qr/^\s*--disable_.*/, '' ],
      [ qr/^\s*--(?:send|reap)/, '' ],
      [ qr/^\s*--source\s.*/, '' ],
      [ qr/^\s*--delimiter\s.*/, '' ],
      [ qr/,rqg,/, ',root,' ],
      [ qr/^\s*(?:CREATE\s+USER\s+rqg|GRANT\s*TO\s+rqg).*/, '' ],
      [ qr/^\s*--(?:connect|disconnect).*/, '' ],
    );

    foreach my $p (@patterns) {
      print "\n\nNew replacement: $p->[0] => $p->[1]\n";

      my $count= 0;
      my @new_test= ();
      foreach my $s (@test) {
        if (my $n = ($s =~ s/$p->[0]/$p->[1]/isg)) {
          $count+= $n;
        }
        push @new_test, $s;
      }

      if ($count) {
        print "Found $count occurrences of the pattern\n";
        if ( run_test( \@new_test ) )
        {
          @last_failed_test= @new_test;
          @test= @new_test;
          print "Clause $p->[0] has been replaced with $p->[1]\n";
        }
        else {
          print "Keeping clause $p->[0]\n";
          @test= @last_failed_test;
        }
      }
      else {
        print "Haven't found any occurrences of the pattern\n";
      }
    }
  }
  elsif ($mode eq 'options') {

    my @test= @last_failed_test;
    if (scalar(@test) <= 1) {
      exit;
    }

    # Option groups, those that are easier to remove together

    my @option_groups= (qr/(?:encrypt|key[-_]management|hashicorp)/,qr/innodb[-_]/,qr/performance[-_]schema/,qr/s3/);

    foreach my $og (@option_groups)
    {
      my @opts= ();
      my @opts_to_remove= ();

      foreach my $o (@options) {
        if ($o =~ /$og/) {
          push @opts_to_remove, $o;
        } else {
          push @opts, $o;
        }
      }

      if (scalar(@opts_to_remove)) {
        print "\nTrying to remove options @opts_to_remove\n";
        my @options_save= @options;
        @options= @opts;
        if ( run_test( \@test ) )
        {
          print "Options @opts_to_remove can be removed\n";
        }
        else {
          print "Keeping options @opts_to_remove\n";
          @options= @options_save;
        }
      }
    }

    # Individual options

    my @opts= @options;
    my @opts_to_preserve= ();
    foreach my $i (0..$#opts) {
      if ($opts[$i] =~ /--(?:mem|vardir)/) {
        push @opts_to_preserve, $opts[$i];
        next;
      }
      @options= (@opts_to_preserve, @opts[$i+1..$#opts]);
      print "\nTrying to remove option $opts[$i]\n";
      if ( run_test( \@test ) )
      {
        print "Option $opts[$i] can be removed\n";
      }
      else {
        print "Keeping option $opts[$i]\n";
        push @opts_to_preserve, $opts[$i];
      }
    }
  }
  elsif ($mode eq 'cleanup') {

    my @test= @last_failed_test;
    my @new_test= ();
    my $count= 0;
    foreach my $s (@test) {
      if ($s =~ /^\s*$|^\s*--\s*disable_abort_on_error/s) {
        $count++;
        next;
      }
      unless ($s =~ /delimiter/) {
        if (my $n = ($s =~ s/(?:\s+([;\)]))/$1/isg)) {
          $count+= $n;
        }
        if (my $n = ($s =~ s/(?:\(\s+)/\(/isg)) {
          $count+= $n;
        }
      }
      if (my $n = ($s =~ s/^\s+//isg)) { $count+= $n }
      while (my $n = ($s =~ s/  / /isg)) { $count+= $n }

      push @new_test, $s;
    }

    if ($count) {
      print "\n$count replacement(s) have been made\n\n";
      if ( run_test( \@new_test ) )
      {
        @last_failed_test= @new_test;
        @test= @new_test;
        print "Cleanup was successful\n";
      }
      else {
        print "Leaving the test dirty\n";
      }
    }
    else {
      print "Haven't made any replacements\n";
    }
  }
}

print "\nLast reproducible testcase: $suitedir/$testcase.test.reproducible.".($reproducible_counter-1)."\n";
print "Basedir: ".dirname(abs_path(cwd()))."\n";
print "Vardir: $vardir\n";
print "Remaining options: @options\n\n";

# THE END

##############
# Subroutines
##############

# Returns 1 if the test fails as expected,
# and 0 otherwise
sub run_test
{
  if ($with_minio) {
    system("mc alias set local http://127.0.0.1:9000 minio minioadmin && ( mc rb --force local/rqg || true ) && mc mb local/rqg");
  }
  my $testref = shift;
  
  if ($endtime and ( time() + $max_trial_duration > $endtime )) {
    print "Only " . ($endtime - time()) . " seconds left till simplification timeout, while the longest trial took $max_trial_duration seconds. Quitting with what we have\n";
    exit 2;
  }
  print "Size of the test to run: " . scalar(@$testref) . "\n";

  write_testfile($testref);

  my $result;

  my $i= 1;
  while ($i <= $trials) {
    my $start = time();
    print sprintf("Trial $i out if $trials started %02d-%02d %02d:%02d:%02d\n",(localtime($start))[4]+1,(localtime($start))[3],(localtime($start))[2],(localtime($start))[1],(localtime($start))[0]);
    $testcase_timeout= my_min(my_max(int(($timeout-15)/60),1),300);

    my $test_result= undef;
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
      unless (defined $test_result) {
        print "The trial timed out\n";
        kill '-KILL', $pid;
        waitpid($pid, undef);
        $test_result= 1;
        $result= 0;
      }
    }
    elsif (defined $pid) {
      print "Trial timeout: $timeout sec, testcase timeout: $testcase_timeout min\n";

      system( "perl mysql-test-run.pl --nocheck-testcases --nowarnings --force-restart @options --suite=$suitename $test_basename --testcase-timeout=$testcase_timeout > $testcase.output/$testcase.out.last 2>&1" );
      exit $? >> 8;
    } else {
      print "ERROR: Could not fork for running the test\n";
      exit 1;
    }

    my $out= readpipe("cat $testcase.output/$testcase.out.last");
    my $errlog = ( $ENV{MTR_VERSION} eq "1" ? "$vardir/log/master.err" : "$vardir/log/mysqld.1.err");

    my $separ= $/;
    $/= undef;
    if (open(ERRLOG, "$errlog")) {
        $out.= <ERRLOG>;
        close(ERRLOG);
    } else {
        print "ERROR: Cannot open $errlog: $!\n";
    }
    if (-e "$vardir/log/mysqld.2.err") {
      open(ERRLOG, "$vardir/log/mysqld.2.err") || print "Cannot open $vardir/log/mysqld.2.err\n" && exit 0;
      $out.= <ERRLOG>;
      close(ERRLOG);
    }
    $/= $separ;

    my $trial_duration= time() - $start;
    $max_trial_duration= $trial_duration if $trial_duration > $max_trial_duration;
    print "Trial $i duration: $trial_duration\n";

    # Refined diagnostics
    if (scalar @output) {
      $result= 1;
      foreach my $output (@output) {
        $output= qr/$output/s;
        $result= ( $out =~ /$output/ );
        last unless $result;
      }
      if ($result) {
        print "--------------------------\n";
        print "---- REPRODUCED (no: $reproducible_counter)\n";
        print "--------------------------\n";
      } else {
        print "Could not reproduce - trial $i ".($test_result ? "failed, but" : "passed, and")." output didn't match the pattern\n";
      }
    }
    elsif ($test_result) {
      $result= $test_result;
      print "--------------------------\n";
      print "---- REPRODUCED (no: $reproducible_counter) - test failed, and there was no pattern to match\n";
      print "--------------------------\n";
    }
    else {
      print "Could not reproduce - test passed, and there was no pattern to match\n";
    }

    my $outfile;
    if ($result) {
        $outfile= "$testcase.output/$testcase.out.reproducible.$reproducible_counter";
        my $old_timeout= $timeout;
        $timeout= my_max(my_min($timeout, $trial_duration*2),$min_timeout);
    } else {
        $outfile= "$testcase.output/$testcase.out.not_reproducible.$not_reproducible_counter";
        if ($trial_duration > $testcase_timeout * 60 and $testcase_timeout >= 30 and $i < $trials - 1) {
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
  print "Last reproducible testcase so far: ".($reproducible_counter ? "$suitedir/$testcase.test.reproducible.".($reproducible_counter-1) : "<none>")."\n";
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
  my $current_con= 'default';
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
      if ($cmd =~ /$preserve_pattern/) {
        $preserve_connections{$current_con}= 1;
      }
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

  my $progress_made= 0;

  foreach my $c (@_)
  {
    ++$counter;
    if ($preserve_connections{$c}) {
      print "Connection $c is on the preserve list, keeping it\n\n";
      next;
    }

    my @new_test = ();
    my $current_con= 'default';
    foreach my $t (@last_failed_test) {
      if ( $t =~ /^\s*\-\-(?:connect\s*\(\s*|disconnect\s+|connection\s+)([^\s\,]+)/s )
      {
        $current_con= $1;
      }
      push @new_test, $t unless ($current_con eq $c);
    }
    print "Trying to remove connection $c ($counter out of " . scalar(@_) . ")\n";
    if (run_test(\@new_test)) {
      print "Connection $c is not needed\n\n";
      @last_failed_test= @new_test;
      $progress_made= 1;
    } else {
      print "Saving connection $c\n\n";
    }
  }
  return $progress_made;
}

# On some reason, I sometimes get wrong results with the built-in 'min' function
# when it's executed like this: min($a,$#b), but not when $#b is assigned to a variable.
# my_min subroutine is meant to work around this.
# I don't know if it can happen with my_max, so adding it just to be safe
sub my_min {
  my @args= @_;
  return min(@args);
}
sub my_max {
  my @args= @_;
  return max(@args);
}
