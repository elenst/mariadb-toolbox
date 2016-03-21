package My::Suite::Scaledb;

use My::SafeProcess;
use My::File::Path;
use Cwd;
use mtr_report;

@ISA = qw(My::Suite);

# Look for ScaleDB binaries.
my $exe_scaledb_cas = "$::basedir/storage/scaledb/scaledb_cas";
my $exe_scaledb_slm = "$::basedir/storage/scaledb/scaledb_slm";
my $scaledb_cas_config = "$::opt_vardir/cas.conf";
my $scaledb_slm_config = "$::opt_vardir/slm.conf";

return "No ScaleDB binaries" 
  unless $exe_scaledb_cas and -x $exe_scaledb_cas 
         and $exe_scaledb_slm and -x $exe_scaledb_slm ;

mkpath("$::opt_vardir/scaledb_data");
mkpath("$::opt_vardir/scaledb_logs");

sub write_conf {
  my ($config, $component) = @_; 
  my $res;

  foreach my $group ($config->groups()) {
    my $name= $group->{name};
    # Only the ones relevant to scaledb_cas.
    next unless $name eq $component;
    foreach my $option ($group->options()) {
      $res .= $option->name();
      my $value= $option->value();
      if (defined $value) {
	$res .= "=$value";
      }
      $res .= "\n";
    }
  }
  $res;
}

sub write_cas_conf {
  my ($config) = @_; # My::Config
  write_conf($config,'scaledb_cas');
}

sub write_slm_conf {
  my ($config) = @_; # My::Config
  write_conf($config,'scaledb_slm');
}

sub write_scaledb_conf {
  my ($config) = @_; # My::Config
  write_conf($config,'scaledb');
}

sub binary_start {
  my ($conf, $test, $binary, @args) = @_; # My::Config::Group, My::Test

  return if $conf->{proc}; # Already started

  # Then start the searchd daemon.
  my $args;
  &::mtr_init_args(\$args);
  foreach (@args) {
    &::mtr_add_arg($args, $_);
  }
  $conf->{'proc'}= My::SafeProcess->new
    (
     name         => $conf->name(),
     path         => $binary,
     args         => \$args,
     output       => "$::opt_vardir/scaledb_safeproc.err",
     error        => "$::opt_vardir/scaledb_safeproc.err",
     append       => 1,
     nocore       => 1,
    );
  &::mtr_verbose(time()." Started $conf->{proc}");
}

sub scaledb_cas_start {
  my ($scaledb_cas, $test) = @_; # My::Config::Group, My::Test

#  my $cmd= "\"$exe_scaledb_cas\" \"$scaledb_cas_config\" 0.0.0.0 13306 2>&1 &";
#  &::mtr_verbose("cmd: $cmd");
#  system $cmd;
   binary_start($scaledb_cas, $test, $exe_scaledb_cas, $scaledb_cas_config, '0.0.0.0','13306');
}

sub scaledb_slm_start {
  my ($scaledb_slm, $test) = @_; # My::Config::Group, My::Test

#  my $cmd= "\"$exe_scaledb_slm\" \"$scaledb_slm_config\" 2>&1 &";
#  &::mtr_verbose("cmd: $cmd");
#  system $cmd;
   binary_start($scaledb_slm, $test, $exe_scaledb_slm, $scaledb_slm_config);

}

sub scaledb_wait {
  my ($scaledb, $port) = @_; 
  my $wait_sec = 30;
  while ($wait_sec--) {
    sleep 1;
    system("echo PING | nc 127.0.0.1 $port > /dev/null 2>&1 ");
    return 0 unless $?;
  }
  return 1;
}

sub scaledb_cas_wait {
  my ($scaledb) = @_; # My::Config::Group
  scaledb_wait($scaledb, 13306);
}

sub scaledb_slm_wait {
  my ($scaledb) = @_; # My::Config::Group
  scaledb_wait($scaledb, 43306);
}

############# declaration methods ######################

sub config_files() {
  (
    'cas.conf' => \&write_cas_conf,
    'slm.conf' => \&write_slm_conf,
    'scaledb.conf' => \&write_scaledb_conf,
  )
}

sub servers {
  ( 'scaledb_cas' => {
      SORT => 400,
      START => \&scaledb_cas_start,
      WAIT => \&scaledb_cas_wait,
    },
    'scaledb_slm' => {
      SORT => 500,
      START => \&scaledb_slm_start,
      WAIT => \&scaledb_slm_wait,
    },
  )
}

sub is_default { 1 }

############# return an object ######################
bless { };

