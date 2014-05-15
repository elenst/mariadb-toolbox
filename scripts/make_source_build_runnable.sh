#!/bin/bash

if [ $# -lt 1 ]
then
  echo "Usage $0 <basedir>"
  exit
fi

basedir=$1

if [ ! -d $basedir ]
then
  echo "ERROR: Basedir $basedir does not exist!"
  exit
fi

if [ ! -e $basedir/bin ]
then
  mkdir $basedir/bin
elif [ ! -d $basedir/bin ]
then
  echo "ERROR: $basedir/bin exists, and it's not a folder!"
  exit
fi

if [ ! -e $basedir/share ]
then
  mkdir $basedir/share
elif [ ! -d $basedir/share ]
then
  echo "ERROR: $basedir/share exists, and it's not a folder!"
  exit
fi

ln -s $basedir/extra/my_print_defaults $basedir/bin/my_print_defaults
ln -s $basedir/scripts/fill_help_tables.sql $basedir/share/fill_help_tables.sql
ln -s $basedir/scripts/mysql_system_tables.sql $basedir/share/mysql_system_tables.sql
ln -s $basedir/scripts/mysql_system_tables_data.sql $basedir/share/mysql_system_tables_data.sql
ln -s $basedir/scripts/mysql_test_data_timezone.sql $basedir/share/mysql_test_data_timezone.sql
ln -s $basedir/scripts/mysql_performance_tables.sql $basedir/share/mysql_performance_tables.sql
ln -s $basedir/sql/mysqld $basedir/bin/mysqld
ln -s $basedir/extra/resolveip $basedir/bin/resolveip
ln -s $basedir/sql/share/english $basedir/share/english
ln -s $basedir/scripts/mysqld_safe $basedir/bin/mysqld_safe
chmod u+x $basedir/scripts/mysql_install_db

