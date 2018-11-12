use Getopt::Long;
use strict;

my $build_location= '/data/bld';
my $src_location= '/data/src';
my $branch_list= '10.0,10.1,10.2,10.3,10.4';
my $stopfile= "$ENV{HOME}/test_loop.stop";
my $pausefile= "$ENV{HOME}/test_loop.pause";
my $rqg= "/data/src/rqg-test_loop";
my $test_list= 'combo';
my $log_location= "$ENV{HOME}/test_loop_logs";
my $help= 0;

my $opt_result= GetOptions(
  'branches=s' => \$branch_list,
  'builds=s' => \$build_location,
  'help' => \$help,
  'logs=s' => \$log_location,
  'pausefile=s' => \$pausefile,
  'rqg=s' => \$rqg,
  'sources=s' => \$src_location,
  'stopfile=s' => \$stopfile,
  'tests=s' => \$test_list,
);

sub help {
  print <<EOF

$0 - Runs regression tests in a loop unless interrupted or paused

Options:
  --branches         : list of branches to test, default $branch_list
  --builds           : common location of basedirs, default $build_location
  --help             : print this help and exit
  --logs             : common location of logs, default $log_location
  --pausefile        : file which, if exists, will make the loop pause after the current test run 
                       and wait till the file disappears
  --rqg              : RQG location, default $rqg
  --sources          : common location of sourcedirs, default $src_location
  --stopfile         : file which, if exists, will make the loop stop after the current test run
  --tests            : list of tests to run, default $test_list

EOF
;
}

if (!$opt_result) {
    print STDERR "\nERROR: Error occured while reading options\n\n";
    help();
    exit 1;
}

if ($help) {
  help();
  exit 0;
}

my @branches= split /,/, $branch_list;
my @tests= split /,/, $test_list;

my %last_tried_revision= ();

while (1) {

  # First we'll skip all branches that haven't been changed since last test run.
  # If it turns out that nothing has been changed and everything was skipped, we'll to the next due branch and run tests on it anyway
  
  my $all_skipped= 1; 
  my $next_branch= undef;

  foreach my $branch (@branches) {

    check_stopfile();
    check_pausefile();
    
    if (git_pull($branch)) {
      print_log( "ERROR: failed to run git pull on branch $branch" );
      next; # Next branch
    }
    my $revision= git_revision($branch);
    my $prev_revision= $last_tried_revision{$branch} || 'N/A';
    
    if ( $revision eq $prev_revision ) {
      print_log( "Revision $revision on branch $branch has been already tested or tried, skipping for now" );
      $next_branch= $branch unless defined $next_branch;
      next; # Next branch
    }
    
    print_log( "##################################################################" );
    print_log( "# Revision $revision, branch $branch" );
    print_log( "##################################################################" );

    $all_skipped= 0;
    $last_tried_revision{$branch}= $revision;

    if (build_server($branch,$revision)) {
      print_log( "ERROR: failed to build branch $branch revision $revision" );
      next; # Next branch
    }
    
    run_tests($branch, $revision);
  }
  
  if ($all_skipped) {

    print_log( "# No changes in branches have been detected, running tests on $next_branch" );

    print_log( "##################################################################" );
    print_log( "# Revision $last_tried_revision{$next_branch}, branch $next_branch (re-run)" );
    print_log( "##################################################################" );

    run_tests($next_branch, $last_tried_revision{$next_branch});
  }
}

sub run_tests {
  my $branch= shift;
  my $revision= shift;

  foreach my $test (@tests) {

    check_stopfile();
    check_pausefile();

    my $config= "conf/mariadb/${branch}-${test}.cc";
    next unless -e "$rqg/$config";
    my $workdir= $log_location.'/'.$branch.'-'.ts_alphanum().'-'.$test.'-'.substr(${revision},0,8);
    my $cmd= "perl ./combinations.pl --new --force --run-all-combinations-once --config=$config --basedir=$build_location/${branch}-testloop --workdir=$workdir";
    
    print_log( "# Running $cmd", "" );
    system("cd $rqg ; git pull ; RQG_HOME=$rqg $cmd");
  }

}

sub check_stopfile {
  if (-e $stopfile) {
    print_log( "Stop file has been found, finishing the loop" );
    exit;
  }
}

sub check_pausefile {
  while (-e $pausefile) {
    print_log( "Pause file has been found, waiting for 5 minutes" );
    sleep 300;
  }
}

sub git_pull {
  my $b= shift;
  print_log( "Trying to pull in $src_location/$b" );
  system("cd $src_location/$b ; git clean -dfx ; git submodule foreach --recursive git clean -xdf ; git pull");
  return $?;
}

sub git_revision {
  my $b= shift;
  my $rev= readpipe("cd $src_location/$b ; git log --format='%H' -1");
  chomp $rev;
  return $rev;
}

sub build_server {
  my $b= shift;
  my $revision= shift;

  if (-e "$build_location/${b}-testloop/last_build") {
    open(LAST_BUILD, "$build_location/${b}-testloop/last_build");
    my $prev_revision = <LAST_BUILD>;
    chomp $prev_revision;
    $prev_revision =~ s/^\#\s//;

    if ($prev_revision eq $revision) {
      print_log("$b $revision has already been built");
      return 0;
    }
    else {
      print_log("Previous built revision on $b was $prev_revision, rebuilding");
    }
  }

  print_log( "# Building $b" );
  system("rm -rf $build_location/ongoing_build");
  system("mkdir $build_location/ongoing_build");
  open(LAST_BUILD,">$build_location/ongoing_build/last_build") || print_log( "ERROR: Could not open $build_location/ongoing_build/last_build for writing" );
  print LAST_BUILD "# $revision\n#\n";
  print LAST_BUILD "cmake $src_location/$b -DCMAKE_INSTALL_PREFIX=$build_location/${b}-testloop -DCMAKE_BUILD_TYPE=Debug\n";
  print LAST_BUILD "make -j5\n";
  print LAST_BUILD "make install\n";
  close(LAST_BUILD);
  system("cd $build_location/ongoing_build ; . $build_location/ongoing_build/last_build");
  my $build_res= $?;
  if ($build_res == 0) {
    system("cp $build_location/ongoing_build/last_build $build_location/${b}-testloop/last_build");
  }
  return $build_res;
}

sub ts {
  my ($sec, $min, $hour, $day, $month, $year, undef, undef, undef) = localtime();
  $year+= 1900;
  $month+= 1;
  return sprintf("%4d-%02d-%02dT%02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);
}

sub ts_alphanum {
  my ($sec, $min, $hour, $day, $month, $year, undef, undef, undef) = localtime();
  $year+= 1900;
  $month+= 1;
  return sprintf("%4d%02d%02dT%02d%02d%02d", $year, $month, $day, $hour, $min, $sec);
}

sub print_log {
  my @lines= @_;
  foreach my $l (@lines) {
    print ts().' '.$l."\n";
  }
}
