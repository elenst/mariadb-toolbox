#!/usr/bin/perl

use Getopt::Long;
use Getopt::Long qw( :config pass_through );
use strict;

my ($branch, $build_type, $alias, $bin_home, $rqg_home, $config, $logdir, $queue_file);
$build_type= '';

GetOptions (
  "bin-home=s" => \$bin_home,
  "rqg-home=s" => \$rqg_home,
  "branch=s" => \$branch,
  "build=s" => \$build_type,
  "alias=s" => \$alias,
  "config=s" => \$config,
  "logdir=s" => \$logdir,
  "queue=s" => \$queue_file,
);

if ($?) {
    sayLastWords("Unknown option");
}

unless (defined $branch) {
    sayLastWords("Branch under test must be specified");
}

unless (defined $alias) {
    sayLastWords("Test alias must be specified");
}

unless ($build_type) {
    say("Build type (rel|asan|gcov|debug) not specified, will use the base name");
}

unless ((defined $bin_home
            and defined $rqg_home
            and defined $logdir
            and defined $queue_file
        ) or (defined $ENV{TEST_HOME}))
{
    sayLastWords("All of bin-home, rqg-home, logdir, queue must be defined, or TEST_HOME environment variable must be set\n");
}

$bin_home   ||= "$ENV{TEST_HOME}/bld";
$rqg_home   ||= "$ENV{TEST_HOME}/rqg";
$logdir     ||= "$ENV{TEST_HOME}/logs";
$queue_file ||= "$ENV{TEST_HOME}/test_queue";

if ($config and ! -e $config) {
    $config= "$rqg_home/$config";
}

unless ("@ARGV" =~ /basedir/) {
    push @ARGV, ($build_type ? "--basedir=$bin_home/${branch}-${build_type}" : "--basedir=$bin_home/${branch}");
}

my $cmd= "RQG_HOME=$rqg_home perl $rqg_home/combinations.pl --dry-run --config=$config --workdir=$logdir/dummy --run-all-combinations-once @ARGV | sed -e 's/.*perl /perl /g'";

# Allow providing only relative names for basedirs
$cmd=~ s/basedir(\d?=)([^\/])/basedir${1}$bin_home\/$2/g;

my $num=`$cmd | grep -c runall`;
chomp $num;

say("Scheduling $num test(s) for:\n\ttest alias: $alias\n\tbranch: $branch\n\tbuild type: $build_type\n\tconfig: $config");
system('echo "### TEST_ALIAS='.$alias.'" >> '.$queue_file);
system('echo "### SERVER_BRANCH='.$branch.'" >> '.$queue_file);
system("$cmd >> $queue_file");


sub say {
    my $ts= sprintf("%04d-%02d-%02d %02d:%02d:%02d",(localtime())[5]+1900,(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0]);
    my @lines= ();
    map { push @lines, split /\n/, $_ } @_;
    foreach my $l (@lines) {
        print $ts, ' ', $l, "\n";
    }
}

sub sayLastWords {
    my $ts= sprintf("%04d-%02d-%02d %02d:%02d:%02d",(localtime())[5]+1900,(localtime())[4]+1,(localtime())[3],(localtime())[2],(localtime())[1],(localtime())[0]);
    my @lines= ();
    map { push @lines, split /\n/, $_ } @_;
    foreach my $l (@lines) {
        print $ts, ' [FATAL ERROR] ', $l, "\n";
    }
    die;
}
