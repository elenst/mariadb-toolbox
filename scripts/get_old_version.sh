#!/bin/bash
#
#  Copyright (c) 2017, 2020, MariaDB
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

set -xe

LOCATION=${OLD_VERSION_LOCATION:-"$HOME/old_versions"}

if [ ! -e $LOCATION ] ; then
  mkdir -p $LOCATION
fi

for OLD in "$@" ; do
    cd $LOCATION
    rm -f index.html
    case $OLD in
    mysql-5.5)
      ver=mysql-5.5.62
      echo "MySQL version $ver (last MySQL 5.5)"
      fname=mysql-5.5.62-linux-glibc2.12-x86_64
      wget_link=https://downloads.mysql.com/archives/get/p/23/file/${fname}.tar.gz
    ;;
    mysql-*)
      ver=`echo $OLD | sed -e 's/mysql-//'`
      if [[ $ver =~ ^[0-9]\.[0-9]\.[0-9] ]] ; then
        major_ver=`echo $ver | sed -e 's/\([0-9]*\.[0-9]*\)\.*/\1/'`
      elif [[ $ver =~ ^[0-9]\.[0-9]$ ]] ; then
        major_ver=$ver
        wget https://dev.mysql.com/doc/relnotes/mysql/$major_ver/en/
        ver=`grep -i 'General Availability' index.html  | grep -v 'Not yet released' | grep section | head -1 | sed -e 's/.*Changes in MySQL \([0-9]*\.[0-9]*\.[0-9]*\).*/\1/'`
      fi
      echo "MySQL version $ver"
      fname=mysql-${ver}-linux-glibc2.12-x86_64
      wget_link=https://dev.mysql.com/get/Downloads/MySQL-${major_ver}/${fname}.tar.gz
      ver=mysql-$ver
    ;;
    10.*|5.*)
      wget https://downloads.mariadb.com/MariaDB/mariadb-${OLD}/bintar-linux-x86_64/
      fname=`grep "\"mariadb-.*tar.gz\"" index.html | grep ${OLD} | sed -e 's/.*\(mariadb-.*\)\.tar\.gz.*/\1/'`
      ver=`echo $fname | sed -e 's/.*mariadb-\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/'`
      wget_link=https://downloads.mariadb.com/MariaDB/mariadb-${OLD}/bintar-linux-x86_64/${fname}.tar.gz
    ;;
    *)
    ;;
    esac

    if [ -e $LOCATION/$ver ] ; then
      echo "The version $ver already exists"
      continue
    fi

    if ! wget -nv $wget_link -O $LOCATION/$ver.tar.gz ; then
      echo "Failed to fetch $wget_link"
      continue
    fi

    mkdir $LOCATION/$ver
    if [ "$OLD" != "$ver" ] ; then
      rm -f $OLD
      ln -s $ver $OLD
    fi
    cd $LOCATION/$ver
    tar zxf $LOCATION/$ver.tar.gz
    rm $LOCATION/$ver.tar.gz
    rm -f $LOCATION/index.html
    dname=`ls`
    mv $dname/* ./
    rmdir $dname
    # Workaround for MDEV-17294
    rm -f lib/plugin/ha_tokudb.so
done
set +xe
