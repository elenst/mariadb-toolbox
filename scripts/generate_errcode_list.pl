# Formats known MariaDB error codes in "use constant" format for MySQL.pm
# First argument is a path to the server basedir (since the constants
# may depend on the version). Second and third arguments are the first
# and the last error code to form the range

use strict;

my $basedir= $ARGV[0];
my $perror;
if (-x "$basedir/bin/perror") {
  $perror= "$basedir/bin/perror";
} elsif (-x "$basedir/extra/perror") {
  $perror= "$basedir/extra/perror";
} else {
  print "ERROR: First argument must be a path to the basedir\n";
  exit 1;
}

my ($first, $last) = ($ARGV[1], $ARGV[2]);
if ($first !~ /^\d+$/) {
  print "ERROR: Second argument must be a number representing an error code\n";
  exit 1;
}
if ($last !~ /^\d+$/) {
  print "ERROR: Third argument must be a number representing an error code\n";
  exit 1;
}

if ($first > $last) {
  print "ERROR: Second argument must be a number less or equal the third argument\n";
  exit 1;
}

foreach my $e ($first .. $last) {
  my $str= `$perror $e`;
  chomp $str;
  if ($str =~ /^Illegal error code:$/) {
    print "# Illegal error code $e\n";
  } elsif ($str =~ /MariaDB error code $e \((\w+)\): (.*)/) {
    my ($errcode, $errstr)= ($1, $2);
    if (length($errstr) > 90) {
      $errstr= substr($errstr,0,85).'<...>';
    }
    my $padding= 51 - length($errcode);
    $padding= 1 if $padding < 1;
    
    print sprintf("use constant  %s %${padding}s $e; # %s\n", $errcode, '=>', $errstr);
  } else {
    print "Unexpected output: $str\n";
  }
}

