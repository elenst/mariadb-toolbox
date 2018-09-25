#
#  Copyright (c) 2017, MariaDB
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

use strict;

# Options which can be adjusted
my ($duration, $basedirs);

my @option_blocks;

# Regarding innodb_log_compressed_pages, see MDEV-13247

my $common_options=
    ' --no-mask'
  . ' --seed=time'
  . ' --threads=4'
  . ' --queries=100M'
  . ' --mysqld=--loose-max-statement-time=20'
  . ' --mysqld=--loose-lock-wait-timeout=20'
  . ' --mysqld=--loose-innodb-lock-wait-timeout=10'
  . ' --mysqld=--loose-innodb_log_compressed_pages=on'
;

if ($ENV{GLOBAL_RQG_OPTIONS}) {
  $common_options .= ' '.$ENV{GLOBAL_RQG_OPTIONS};
}
if ($ENV{JOB_RQG_OPTIONS}) {
  $common_options .= ' '.$ENV{JOB_RQG_OPTIONS};
}
if ($ENV{TEST_RQG_OPTIONS}) {
  $common_options .= ' '.$ENV{TEST_RQG_OPTIONS};
}

my $test_data_dir=($ENV{SCRIPT_DIR} ? "$ENV{SCRIPT_DIR}/../data" : "$ENV{TRAVIS_BUILD_DIR}/data");

#        . ' --mysqld=--log-bin'
#        . ' --mysqld=--binlog-format=ROW'

if (defined $ENV{TYPE}) {
  my @type_options= ();
  my @types= split ',', $ENV{TYPE};
  my $scenario;
  foreach my $t (@types) {
    $t= lc($t);
    if ($t =~ /^(?:normal|upgrade|undo|crash|recovery|undo-recovery|downgrade)/) {
      $duration= ($t =~ /undo/ ? 200 : 90);
      if ($t =~ /recovery/) {
        $basedirs= ' --basedir='.$ENV{BASEDIR};
      }
      elsif ($t =~ /downgrade/) {
        $basedirs= ' --basedir2='.$ENV{HOME}.'/old --basedir1='.$ENV{BASEDIR};
      }
      else {
        $basedirs= ' --basedir1='.$ENV{HOME}.'/old --basedir2='.$ENV{BASEDIR};
      }
      if ($t eq 'normal' or $t eq 'upgrade' or $t eq 'downgrade') {
        $scenario= 'Upgrade';
      } elsif ($t eq 'crash' or $t eq 'recovery' or $t eq 'crash-downgrade') {
        $scenario= 'CrashUpgrade';
      } else {
        $scenario= 'UndoLogUpgrade';
      }

# TODO: Add vcols back after MDEV-17199, MDEV-17215, MDEV-17218 are fixed
#        . ' --vcols'

      push @type_options,
          ' --grammar=conf/mariadb/oltp-transactional.yy'
        . ' --grammar2=conf/mariadb/oltp_and_ddl.yy'
        . ' --gendata=conf/mariadb/innodb_upgrade.zz'
        . ' --gendata-advanced'
        . ' --mysqld=--server-id=111'
        . ' --scenario='.$scenario
        . ' --duration='.$duration
        . $basedirs
      ;
    }
  }
  push @option_blocks, \@type_options;
}

if (defined $ENV{ENCRYPTION}) {
  my @encryption_options;
  my @encryptions= split ',', $ENV{ENCRYPTION};
  foreach my $e (@encryptions) {
    $e= lc($e);
    if ($e eq 'on') {
        push @encryption_options,
            ' --mysqld=--file-key-management'
          . ' --mysqld=--file-key-management-filename='.$test_data_dir.'/keys.txt'
          . ' --mysqld=--plugin-load-add=file_key_management.so'
          . ' --mysqld=--innodb-encrypt-tables'
          . ' --mysqld=--innodb-encrypt-log'
          . ' --mysqld=--innodb-encryption-threads=4'
          . ' --mysqld=--aria-encrypt-tables=1'
          . ' --mysqld=--encrypt-tmp-disk-tables=1'
          . ' --mysqld=--encrypt-binlog'
        ;
    }
    elsif ($e eq 'off') {
      push @encryption_options, '';
    }
    elsif ($e eq 'turn_on') {
        push @encryption_options,
            ' --mysqld2=--file-key-management'
          . ' --mysqld2=--file-key-management-filename='.$test_data_dir.'/keys.txt'
          . ' --mysqld2=--plugin-load-add=file_key_management.so'
          . ' --mysqld2=--innodb-encrypt-tables'
          . ' --mysqld2=--innodb-encrypt-log'
          . ' --mysqld2=--innodb-encryption-threads=4'
          . ' --mysqld2=--aria-encrypt-tables=1'
          . ' --mysqld2=--encrypt-tmp-disk-tables=1'
          . ' --mysqld2=--encrypt-binlog'
        ;
    }
  }
  push @option_blocks, \@encryption_options;
}

if (defined $ENV{PAGE_SIZE}) {
  my @page_sizes;
  if (lc($ENV{PAGE_SIZE}) eq 'all') {
    @page_sizes= ('16K','8K','4K','32K','64K');
  }
  elsif (lc($ENV{PAGE_SIZE}) eq 'small') {
    @page_sizes= ('16K','8K','4K');
  }
  else {
    @page_sizes= split ',', $ENV{PAGE_SIZE};
  }
  my @page_size_options;
  foreach my $s (@page_sizes) {
    push @page_size_options, ' --mysqld=--innodb-page-size='.$s;
  }
  push @option_blocks, \@page_size_options;
}

if (defined $ENV{COMPRESSION}) {
  my @compressions= split ',', $ENV{COMPRESSION};
  my @compression_options;
  foreach my $c (@compressions) {
    my $gendata = ($c eq 'none' ? 'conf/mariadb/innodb_upgrade.zz' : 'conf/mariadb/innodb_upgrade_compression.zz');
    push @compression_options,
        ' --mysqld=--innodb-compression-algorithm='.$c
      . ' --mysqld=--loose-innodb-file-format=Barracuda'
      . ' --mysqld=--loose-innodb-file-per-table=1'
      . ' --gendata='.$gendata
    ;
  }
  push @option_blocks, \@compression_options;
}

if (not defined $duration) {
  $common_options .= ' --duration=300';
}

if (not defined $basedirs) {
  $common_options .= ' --basedir='.$ENV{BASEDIR};
}

push @option_blocks, [ $common_options ];

$combinations= \@option_blocks;
