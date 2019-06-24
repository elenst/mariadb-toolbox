# Expects:
# dist_name (ubuntu | debian) mandatory
# version_name (stretch | bionic | ...) mandatory
# OLD_VERSION major version, mandatory for major upgrade
# NEW_VERSION major version, mandatory
# ARCH (x86_64 | i386), optional, default "x86_64"
# TEST_MODE (server | all | deps), optional, default "server"
# TEST_TYPE (major | minor), optional, default "minor"
# OLD_SERVER (cs | es), optional, default "es"

set -xv

if [[ -z "$NEW_VERSION" ]] ; then
  echo "Server version is not set in NEW_VERSION"
  exit 1
fi

test_mode=${TEST_MODE:-server}
arch=${ARCH:-x86_64}
test_type=${TEST_TYPE:-minor}
old_server=${OLD_SERVER:-es}

if [[ "$test_type" == "major" ]] && [[ -z "$OLD_VERSION" ]] ; then
  echo "Old version is not set in OLD_VERSION for major upgrade"
  exit 1
elif [[ "$test_type" == "minor" ]] ; then
  OLD_VERSION=$NEW_VERSION
fi

major_version=$NEW_VERSION
prev_major_version=$OLD_VERSION

#===============
# This test can be performed in three modes:
# - 'server' -- only mariadb-server is installed (with whatever dependencies it pulls) and upgraded.
# - 'all'    -- all provided packages are installed and upgraded
# - 'deps'   -- only a limited set of main packages is installed and upgraded,
#               to make sure upgrade does not require new dependencies
#===============

echo "Current test mode: $test_mode"

echo "Test properties"
echo "  Test type              $test_type"
echo "  Test mode              $test_mode"
echo "  Major version          $major_version"
echo "  Previous major version $prev_major_version"

#============
# Environment
#============

dpkg -l | grep -iE 'maria|mysql|galera'
lsb_release -a
uname -a
df -kT

#========================================
# Check whether a previous version exists
#========================================

if ! wget http://mirror2.hs-esslingen.de/mariadb/repo/$major_version/$dist_name/dists/$version_name/main/binary-$arch/Packages
then
  echo "Upgrade warning: could not find the 'Packages' file for a previous version in MariaDB repo, skipping the test"
  exit
fi

#===============================================
# Define the list of packages to install/upgrade
#===============================================

server_package="mariadb-server"
test_package="mariadb-test"

case $test_mode in
all)
  package_list=`grep -B 1 'Source: mariadb-' Packages | grep 'Package:' | grep -v 'galera' | awk '{print $2}' | xargs`
  # For the sake of installing TokuDB, disable hugepages
  sudo sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled" || true
  ;;
deps)
  package_list="$server_package mariadb-client mariadb-common $test_package mysql-common libmysqlclient18"
  ;;
server)
  package_list=$server_package
  ;;
*)
  echo "ERROR: unknown test mode: $test_mode"
  exit 1
esac

echo "Package_list: $package_list"

#======================================================================
# Prepare apt source configuration for installation of the last release
#======================================================================

sudo sh -c "echo 'deb http://mirror2.hs-esslingen.de/mariadb/repo/$NEW_VERSION/$dist_name $version_name main' > /etc/apt/sources.list.d/mariadb_upgrade.list"

# We need to pin directory to ensure that installation happens from MariaDB repo
# rather than from the default distro repo

sudo sh -c "echo 'Package: *' > /etc/apt/preferences.d/release"
sudo sh -c "echo 'Pin: origin mirror2.hs-esslingen.de' >> /etc/apt/preferences.d/release"
sudo sh -c "echo 'Pin-Priority: 1000' >> /etc/apt/preferences.d/release"

sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
sudo sh -c 'grep -v "^deb .*file" /etc/apt/sources.list.backup | grep -v "^deb-src .*file" > /etc/apt/sources.list'

# Sometimes apt-get update fails because the repo is being updated.
res=1
for i in 1 2 3 4 5 6 7 8 9 10 ; do
  if sudo apt-get update ; then
    res=0
    break
  fi
  echo "Upgrade warning: apt-get update failed, retrying ($i)"
  sleep 10
done

if [[ $res -ne 0 ]] ; then
  echo "ERROR: apt-get update failed"
  exit $res
fi

#=========================
# Install previous release
#=========================

sudo sh -c "DEBIAN_FRONTEND=noninteractive MYSQLD_STARTUP_TIMEOUT=180 apt-get install --allow-unauthenticated -y $package_list"
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Installation of a previous release failed, see the output above"
  exit 1
fi

#==========================================================
# Wait till mysql_upgrade, mysqlcheck and such are finished
#==========================================================

# Debian installation/upgrade/startup always attempts to execute mysql_upgrade, and
# also run mysqlcheck and such. Due to MDEV-14622, they are subject to race condition,
# and can be executed later or even omitted.
# We will wait till they finish, to avoid any clashes with SQL we are going to execute

function wait_for_mysql_upgrade () {
  res=1
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ; do
    if ps -ef | grep -iE 'mysql_upgrade|mysqlcheck|mysqlrepair|mysqlanalyze|mysqloptimize' | grep -v grep ; then
      sleep 1
    else
      res=0
      break
    fi
  done
  if [[ $res -ne 0 ]] ; then
    echo "ERROR: mysqlcheck or alike have not finished in reasonable time"
  fi
}

wait_for_mysql_upgrade

#================================================================
# Check that the server is functioning and create some structures
#================================================================

if [[ "$NEW_VERSION" == *"10."[4-9]* ]] ; then
# 10.4+ uses unix_socket by default
  sudo mysql -e "set password=password('rootpass')"
else
# Even without unix_socket, on some of VMs the password might be not pre-created as expected. This command should normally fail.
  mysql -uroot -e "set password = password('rootpass')" >> /dev/null 2>&1
fi

# All the commands below should succeed

set -e

mysql -uroot -prootpass -e "CREATE DATABASE db"
mysql -uroot -prootpass -e "CREATE TABLE db.t_innodb(a1 SERIAL, c1 CHAR(8)) ENGINE=InnoDB; INSERT INTO db.t_innodb VALUES (1,'foo'),(2,'bar')"
mysql -uroot -prootpass -e "CREATE TABLE db.t_myisam(a2 SERIAL, c2 CHAR(8)) ENGINE=MyISAM; INSERT INTO db.t_myisam VALUES (1,'foo'),(2,'bar')"
mysql -uroot -prootpass -e "CREATE TABLE db.t_aria(a3 SERIAL, c3 CHAR(8)) ENGINE=Aria; INSERT INTO db.t_aria VALUES (1,'foo'),(2,'bar')"
mysql -uroot -prootpass -e "CREATE TABLE db.t_memory(a4 SERIAL, c4 CHAR(8)) ENGINE=MEMORY; INSERT INTO db.t_memory VALUES (1,'foo'),(2,'bar')"
mysql -uroot -prootpass -e "CREATE ALGORITHM=MERGE VIEW db.v_merge AS SELECT * FROM db.t_innodb, db.t_myisam, db.t_aria"
mysql -uroot -prootpass -e "CREATE ALGORITHM=TEMPTABLE VIEW db.v_temptable AS SELECT * FROM db.t_innodb, db.t_myisam, db.t_aria"
mysql -uroot -prootpass -e "CREATE PROCEDURE db.p() SELECT * FROM db.v_merge"
mysql -uroot -prootpass -e "CREATE FUNCTION db.f() RETURNS INT DETERMINISTIC RETURN 1"

set +e

#====================================================================================
# Store information about server version and available plugins/engines before upgrade
#====================================================================================

mysql -uroot -prootpass --skip-column-names -e "select @@version" | awk -F'-' '{ print $1 }' > /tmp/version.old
mysql -uroot -prootpass --skip-column-names -e "select engine, support, transactions, savepoints from information_schema.engines" | sort > /tmp/engines.old

mysql -uroot -prootpass --skip-column-names -e "select plugin_name, plugin_status, plugin_type, plugin_library, plugin_license from information_schema.all_plugins where plugin_name not in ('DISKS','ROCKSDB_DEADLOCK') order by plugin_name, plugin_library" > /tmp/plugins.old

#=========================================
# Restore apt configuration for local repo
#=========================================

chmod -cR go+r ~/buildbot/debs

if [[ "$test_mode" == "deps" ]] ; then
  # For the dependency check, only keep the local repo
  sudo sh -c "grep -iE 'deb .*file|deb-src .*file' /etc/apt/sources.list.backup > /etc/apt/sources.list"
  sudo rm -rf /etc/apt/sources.list.d/*
else
  sudo cp /etc/apt/sources.list.backup /etc/apt/sources.list
  sudo rm /etc/apt/sources.list.d/mariadb_upgrade.list
fi
sudo rm /etc/apt/preferences.d/release

# Sometimes apt-get update fails because the repo is being updated.
res=1
for i in 1 2 3 4 5 6 7 8 9 10 ; do
  if sudo apt-get update ; then
    res=0
    break
  fi
  echo "Upgrade warning: apt-get update failed, retrying ($i)"
  sleep 10
done

if [[ $res -ne 0 ]] ; then
  echo "ERROR: apt-get update failed"
  exit $res
fi

#=========================
# Install the new packages
#=========================

sudo sh -c "DEBIAN_FRONTEND=noninteractive MYSQLD_STARTUP_TIMEOUT=180 apt-get install --allow-unauthenticated -y $package_list"
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Installation of the new packages failed, see the output above"
  exit 1
fi

#==========================================================
# Wait till mysql_upgrade, mysqlcheck and such are finished
#==========================================================

# Again, wait till mysql_upgrade is finished, to avoid clashes;
# and for non-stable versions, it might be necessary, so run it again
# just in case it was omitted

wait_for_mysql_upgrade

#===================================================
# Check that no old packages have left after upgrade
#===================================================

# The check is only performed for all-package-upgrade, because
# for selective ones some implicitly installed packages might not be upgraded

if [[ "$test_mode" == "all" ]] ; then
  dpkg -l | grep -iE 'mysql|maria' | grep `cat /tmp/version.old`
  if [[ $? -eq 0 ]] ; then
    echo "ERROR: Old packages have been found after upgrade"
    exit 1
  fi
fi

#=====================================================================================
# Check that the server is functioning and previously created structures are available
#=====================================================================================

# All the commands below should succeed

set -e

mysql -uroot -prootpass -e "select @@version, @@version_comment"

mysql -uroot -prootpass -e "SHOW TABLES IN db"
mysql -uroot -prootpass -e "SELECT * FROM db.t_innodb; INSERT INTO db.t_innodb VALUES (3,'foo'),(4,'bar')"
mysql -uroot -prootpass -e "SELECT * FROM db.t_myisam; INSERT INTO db.t_myisam VALUES (3,'foo'),(4,'bar')"
mysql -uroot -prootpass -e "SELECT * FROM db.t_aria; INSERT INTO db.t_aria VALUES (3,'foo'),(4,'bar')"
mysql -uroot -prootpass -e "SELECT * FROM db.t_memory; INSERT INTO db.t_memory VALUES (1,'foo'),(2,'bar')"
mysql -uroot -prootpass -e "SELECT COUNT(*) FROM db.v_merge"
mysql -uroot -prootpass -e "SELECT COUNT(*) FROM db.v_temptable"
mysql -uroot -prootpass -e "CALL db.p()"
mysql -uroot -prootpass -e "SELECT db.f()"

set +e

#===================================================================================
# Store information about server version and available plugins/engines after upgrade
#===================================================================================

set -e

mysql -uroot -prootpass --skip-column-names -e "select @@version" | awk -F'-' '{ print $1 }' > /tmp/version.new
mysql -uroot -prootpass --skip-column-names -e "select engine, support, transactions, savepoints from information_schema.engines" | sort > /tmp/engines.new

mysql -uroot -prootpass --skip-column-names -e "select plugin_name, plugin_status, plugin_type, plugin_library, plugin_license from information_schema.all_plugins where plugin_name not in ('DISKS','ROCKSDB_DEADLOCK') order by plugin_name, plugin_library" > /tmp/plugins.new

ls -l /lib/systemd/system/mariadb.service
ls -l /etc/systemd/system/mariadb.service.d/migrated-from-my.cnf-settings.conf
ls -l /etc/init.d/mysql || true
systemctl --no-pager status mariadb.service
systemctl --no-pager status mariadb
systemctl --no-pager status mysql
systemctl --no-pager status mysqld
systemctl --no-pager is-enabled mariadb

set +e

# This output is for informational purposes
diff -u /tmp/engines.old /tmp/engines.new
diff -u /tmp/plugins.old /tmp/plugins.new

# Only fail if there are any disappeared engines or plugins
disappeared=`comm -23 /tmp/engines.old /tmp/engines.new | wc -l`
if [[ $disappeared -ne 0 ]] ; then
echo "ERROR: the lists of engines in the old and new installations differ"
exit 1
fi
disappeared=`comm -23 /tmp/plugins.old /tmp/plugins.new | wc -l`
if [[ $disappeared -ne 0 ]] ; then
echo "ERROR: the lists of available plugins in the old and new installations differ"
exit 1
fi

diff -u /tmp/version.old /tmp/version.new
if [[ $? -eq 0 ]] ; then
  echo "ERROR: server version has not changed after upgrade"
  echo "It can be a false positive if we forgot to bump version after release,"
  echo "or if it is a development tree is based on an old version"
  exit 1
fi
