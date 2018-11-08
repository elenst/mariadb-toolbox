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

my $opt_result= GetOptions(
  'branches' => \$branch_list,
  'builds' => \$build_location,
  'logs' => \$log_location,
  'pausefile' => \$pausefile,
  'rqg' => \$rqg,
  'sources' => \$src_location,
  'stopfile' => \$stopfile,
  'tests' => \$test_list,
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

my @branches= split /,/, $branch_list;
my @tests= split /,/, $test_list;

my $last_tested_branch= undef;
my %last_tried_revision= ();

while (1) {

  foreach my $branch (@branches) {

    check_stopfile();
    check_pausefile();

    if (git_pull($branch)) {
      print "ERROR: failed to run git pull on branch $branch\n";
      next; # Next branch
    }
    my $revision= git_revision($branch);
    my $prev_revision= $last_tried_revision{$branch} || 'N/A';
    
    if ( $revision eq $prev_revision ) {
      print "Revision $revision on branch $branch has been already tested or tried, skipping for now\n";
      next; # Next branch
    }
    
    print "##################################################################\n";
    print "# Revision $revision, branch $branch\n";
    print "##################################################################\n";

    $last_tried_revision{$branch}= $revision;

    if (build_server($branch)) {
      print "ERROR: failed to build branch $branch revision $revision\n";
      next; # Next branch
    }

    foreach (@tests) {
      my $config= "conf/mariadb/${branch}-combo.cc";
      my $t= time();
      my $workdir= "$log_location/${branch}-${t}-${revision}";
      my $cmd= "perl ./combinations.pl --new --force --run-all-combinations-once --config=$config --basedir=$build_location/${branch}-testloop --workdir=$workdir";
      
      print "# Running $cmd\n\n";
      system("cd $rqg ; git pull ; $cmd");
    }
  }
}

sub check_stopfile {
  if (-e $stopfile) {
    print "Stop file has been found, finishing the loop\n";
    exit;
  }
}

sub check_pausefile {
  while (-e $pausefile) {
    print "Pause file has been found, waiting for 5 minutes\n";
    sleep 300;
  }
}

sub git_pull {
  my $b= shift;
  print "Trying to pull in $src_location/$b\n";
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
  print "# Building $b\n";
  system("rm -rf $build_location/ongoing_build");
  system("mkdir $build_location/ongoing_build");
  open(LAST_BUILD,">$build_location/ongoing_build/last_build") || print "ERROR: Could not open $build_location/ongoing_build/last_build for writing\n";
  print LAST_BUILD "cmake $src_location/b -DCMAKE_INSTALL_PREFIX=$build_location/${b}-testloop -DCMAKE_BUILD_TYPE=Debug\n";
  print LAST_BUILD "make -j5\n";
  print LAST_BUILD "make install\n";
  close(LAST_BUILD);
  system(". $build_location/ongoing_build/last_build");
  return $?;
}
