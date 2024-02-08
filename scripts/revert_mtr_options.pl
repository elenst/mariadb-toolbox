# The script reads my.cnf generated by MTR
# and for each option (except for a few which are needed, locations and such)
# adds to the command line an option reverting the value to default

use Getopt::Long;
use strict;

my $basedir;
my @options;
my %defaults;

GetOptions (
  "basedir=s"   => \$basedir,
);

unless ($basedir) {
  print "ERROR: Basedir must be defined\n";
  exit 1;
}

unless (-d $basedir) {
  print "ERROR: Basedir $basedir does not exist or is not a directory\n";
  exit 1;
}

my $mtr_dir= (-d "$basedir/mysql-test" ? "$basedir/mysql-test" : "$basedir/mariadb-test");
unless (-d $mtr_dir) {
  print "ERROR: MTR dir $mtr_dir does not exist or is not a directory\n";
  exit 1;
}

my $mysqld_binary;
foreach ("$basedir/sql/mariadbd", "$basedir/sql/mysqld", "$basedir/bin/mariadbd", "$basedir/bin/mysqld") {
  if (-x $_) {
    $mysqld_binary= $_;
    last;
  }
}

unless ($mysqld_binary) {
  print "ERROR: MariaDB server executable not found\n";
  exit 1;
}

#print "Running $mysqld_binary --verbose --help\n";
if (open (DEFAULTS, "$mysqld_binary --verbose --help 2>/dev/null | ")) {
  my $in_defaults= 0;
  while (<DEFAULTS>) {
    if ($in_defaults) {
      chomp;
      $_ =~ /^\s*(\S+)\s+(.*)$/;
      my ($opt, $val)= ($1, $2);
      if ($val eq '(No default value)') {
        $val= '';
      }
      $defaults{$opt}= $val;
    }
    elsif (/^---------------------------------/) {
      $in_defaults= 1;
    }
  }
  close(DEFAULTS);
} else {
  print "ERROR: Could not run $mysqld_binary --verbose --help\n";
  exit 1;
}

unless (-e "$mtr_dir/var/my.cnf") {
#  print "Running main.1st to generate my.cnf\n";
  system("cd $mtr_dir; perl mysql-test-run.pl --mem main.1st > /dev/null 2>&1");
}

my $server_section= 0;

open(CNF,"$mtr_dir/var/my.cnf") || die "Could not open $mtr_dir/var/my.cnf: $!\n";
while (<CNF>) {
  next if /^\s*\#/;
  chomp;
  if (/^\s*\[([^\[\]]+)\]\s*$/) {
    my $section= $1;
    if ($section =~ /^mysqld|mariadb|server(?:\.\d+)?$/) {
      $server_section= 1;
    } else {
      $server_section= 0;
    }
    next;
  }
  next unless $server_section;
  my ($opt, $val) = split /=/, $_;
  $opt =~ s/_/-/g;
  my $loose= '';
  if ($opt =~ s/^loose-//) {
    $loose= 1;
  }
  next if ($opt =~ /dir$/) or $opt eq 'user' or $opt eq 'port' or $opt eq 'socket' or $opt eq 'pid-file' or $opt eq 'log-error' or $opt eq 'bind-address' or ($opt =~ /^ssl-/);
  if ($opt =~ s/^skip-plugin/plugin/) {
    next if ($opt =~ /feedback/);
    push @options, '--mysqld=--'.($loose ? 'loose-' : '') . $opt;
  } elsif ( $opt eq 'enable-performance-schema') {
    push @options, '--mysqld=--'.($loose ? 'loose-' : '') . 'disable-performance-schema';
  }
  elsif ($defaults{$opt} ne $val) {
    push @options, '--mysqld=--'.($loose ? 'loose-' : '') . $opt . '=' . $defaults{$opt};
  }
}
close(CNF);

print "@options", "\n";
