# Expects:
# distro (centos | sles | etc) mandatory
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

arch=${ARCH:-x86_64}
test_mode=${TEST_MODE:-server}
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

if [[ "$distro" == "sles123" ]] ; then
    distro="sles12"
fi

repo_dist_arch=$distro-$arch
echo "Architecture and distribution: $repo_dist_arch"

echo "Test properties"
echo "  Test type              $test_type"
echo "  Test mode              $test_mode"
echo "  Major version          $major_version"
echo "  Previous major version $prev_major_version"

cd buildbot

#===============
# This test can be performed in three modes:
# - 'server' -- only mariadb-server is installed (with whatever dependencies it pulls) and upgraded.
# - 'all'    -- all provided packages are installed and upgraded
# - 'deps'   -- only a limited set of main packages is installed and upgraded,
#               to make sure upgrade does not require new dependencies
#===============

echo "Current test mode: $test_mode"

#============
# Environment
#============

rpm -qa | grep -iE 'maria|mysql|galera'
cat /etc/*release
uname -a
df -kT


#========================================
# Check whether a previous version exists
#========================================

if ! wget http://yum.mariadb.org/$prev_major_version/$repo_dist_arch/repodata -O repodata.list
then
  echo "Upgrade warning: could not find the 'repodata' folder for a previous version in MariaDB repo, skipping the test"
  exit
fi

#===============================================
# Define the list of packages to install/upgrade
#===============================================

server_package="MariaDB-server"
test_package="MariaDB-test"

case $test_mode in
all|deps)
  primary_xml=`grep 'primary.xml.gz' repodata.list | sed -e 's/.*href="\(.*-primary.xml\)\.gz\".*/\\1/'`
  wget http://yum.mariadb.org/$prev_major_version/$repo_dist_arch/repodata/$primary_xml.gz
  if [[ $? != 0 ]] ; then
    echo "ERROR: Couldn't download primary.xml.gz from the repository"
    exit 1
  fi
  gunzip $primary_xml.gz
  package_list=`grep -A 1 '<package type="rpm"' $primary_xml | grep MariaDB | grep -vi galera | sed -e 's/<name>//' | sed -e 's/<\/name>//' | xargs`

  if [[ "$test_mode" == "deps" ]] ; then
    package_list=`echo $package_list | xargs -n1 | grep -iE "$server_package|$test_package|MariaDB-client|MariaDB-common|MariaDB-compat" | xargs`
  fi
  ;;
server)
  package_list="$server_package MariaDB-client"
  ;;
*)
  echo "ERROR: unknown test mode: $test_mode"
  exit 1
esac

echo "Package_list: $package_list"

#======================================================================
# Prepare yum/zypper configuration for installation of the last release
#======================================================================

# As of now (February 2018), RPM packages do not support major upgrade.
# To imitate it, we will remove previous packages and install new ones.

if which yum ; then
  package_manager=yum
  repo_location=/etc/yum.repos.d
  install_command="yum -y --nogpgcheck install"
  cleanup_command="yum clean all"
  upgrade_command="yum -y --nogpgcheck upgrade rpms/*.rpm"
  if [[ "$test_type" == "major" ]] ; then
    upgrade_command="yum -y --nogpgcheck install rpms/*.rpm"
  fi
  if yum autoremove 2>&1 |grep -q 'need to be root'; then
    remove_command="yum -y autoremove"
  else
    remove_command="yum -y remove"
  fi
else
  echo "ERROR: could not find package manager"
  exit 1
fi

ls $repo_location/* | grep -iE '(maria|galera)' | xargs -r sudo rm -f

sudo sh -c "echo '[mariadb]
name=MariaDB
baseurl=http://yum.mariadb.org/$prev_major_version/$repo_dist_arch
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' > $repo_location/MariaDB.repo"

sudo sh -c "$cleanup_command"

#=========================
# Install previous release
#=========================

sudo sh -c "$install_command $package_list"
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Installation of a previous release failed, see the output above"
  exit 1
fi

#==========================================================================
# Start the server, check that it is functioning and create some structures
#==========================================================================

if [[ "$distro" == "centos6" ]] ; then
  sudo /etc/init.d/mysql start
else
  sudo systemctl start mariadb
fi

if [[ $? -ne 0 ]] ; then
  echo "ERROR: Server startup failed"
  sudo cat /var/log/messages | grep -iE 'mysqld|mariadb'
  sudo cat /var/lib/mysql/*.err
  exit 1
fi

if [[ "$test_type" == "minor" ]] && [[ "$major_version" > "10.3" ]] ; then
# 10.4+ uses unix_socket by default
  sudo mysql -e "set password=''"
fi

# All the commands below should succeed

set -e

mysql -uroot -e "CREATE DATABASE db"
mysql -uroot -e "CREATE TABLE db.t_innodb(a1 SERIAL, c1 CHAR(8)) ENGINE=InnoDB; INSERT INTO db.t_innodb VALUES (1,'foo'),(2,'bar')"
mysql -uroot -e "CREATE TABLE db.t_myisam(a2 SERIAL, c2 CHAR(8)) ENGINE=MyISAM; INSERT INTO db.t_myisam VALUES (1,'foo'),(2,'bar')"
mysql -uroot -e "CREATE TABLE db.t_aria(a3 SERIAL, c3 CHAR(8)) ENGINE=Aria; INSERT INTO db.t_aria VALUES (1,'foo'),(2,'bar')"
mysql -uroot -e "CREATE TABLE db.t_memory(a4 SERIAL, c4 CHAR(8)) ENGINE=MEMORY; INSERT INTO db.t_memory VALUES (1,'foo'),(2,'bar')"
mysql -uroot -e "CREATE ALGORITHM=MERGE VIEW db.v_merge AS SELECT * FROM db.t_innodb, db.t_myisam, db.t_aria"
mysql -uroot -e "CREATE ALGORITHM=TEMPTABLE VIEW db.v_temptable AS SELECT * FROM db.t_innodb, db.t_myisam, db.t_aria"
mysql -uroot -e "CREATE PROCEDURE db.p() SELECT * FROM db.v_merge"
mysql -uroot -e "CREATE FUNCTION db.f() RETURNS INT DETERMINISTIC RETURN 1"

set +e

#====================================================================================
# Store information about server version and available plugins/engines before upgrade
#====================================================================================

mysql -uroot --skip-column-names -e "select @@version" | awk -F'-' '{ print $1 }' > /tmp/version.old
mysql -uroot --skip-column-names -e "select engine, support, transactions, savepoints from information_schema.engines" | sort > /tmp/engines.old

mysql -uroot --skip-column-names -e "select plugin_name, plugin_status, plugin_type, plugin_library, plugin_license from information_schema.all_plugins where plugin_name not in ('DISKS','ROCKSDB_DEADLOCK') order by plugin_name, plugin_library" > /tmp/plugins.old

#======================================================================
# Prepare yum/zypper configuration for installation of the new packages
#======================================================================

set -e

if [[ "$test_type" == "major" ]] ; then
  echo
  echo "Remove old packages for major upgrade"
  echo
  packages_to_remove=`rpm -qa | grep 'MariaDB-' | awk -F'-' '{print $1"-"$2}' | xargs`
  sudo sh -c "$remove_command $packages_to_remove"
  rpm -qa | grep -iE 'maria|mysql' || true

fi

if [[ "$test_mode" == "deps" ]] ; then
  sudo mv $repo_location/MariaDB.repo /tmp
  sudo rm -rf $repo_location/*
  sudo mv /tmp/MariaDB.repo $repo_location/
  sudo sh -c "$cleanup_command"
fi

#=========================
# Install the new packages
#=========================

# Between 10.3 and 10.4(.2), required galera version changed from galera(-3) to galera-4.
# It means that there will be no galera-4 in the "old" repo, and it's not among the local RPMs.
# So, we need to add a repo for it

if [[ "$test_type" == "major" ]] && [[ "$major_version" > "10.3" ]] && [[ "$prev_major_version" < "10.4" ]] ; then
  sudo sh -c "echo '[galera]
name=Galera
baseurl=http://yum.mariadb.org/galera/repo/rpm/$repo_dist_arch
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1' > $repo_location/galera.repo"
fi

sudo sh -c "$upgrade_command"

set +e

#===================================================
# Check that no old packages have left after upgrade
#===================================================

# The check is only performed for all-package-upgrade, because
# for selective ones some implicitly installed packages might not be upgraded

if [[ "$test_mode" == "all" ]] ; then
  if [ "%(is_main_tree)s" == "yes" ] ; then
    rpm -qa | grep -iE 'mysql|maria' | grep `cat /tmp/version.old`
  else
    rpm -qa | grep -iE 'mysql|maria' | grep `cat /tmp/version.old` | grep -v debuginfo
  fi
  if [[ $? -eq 0 ]] ; then
    echo "ERROR: Old packages have been found after upgrade"
    exit 1
  fi
fi

#================================
# Optionally (re)start the server
#================================

set -e

if [ "$test_type" == "major" ] ; then
  if [[ "$distro" == "centos6" ]] ; then
    sudo /etc/init.d/mysql start
  else
    sudo systemctl start mariadb
  fi

elif [ -n "$extra_restart_after_upgrade" ] ; then
  echo "Due to MDEV-14671, we have to restart the server after upgrade"
  if [[ "$distro" == "centos6" ]] ; then
    sudo /etc/init.d/mysql start
  else
    sudo systemctl start mariadb
  fi
fi

#=====================================================================================
# Run mysql_upgrade for non-GA branches (minor upgrades in GA branches shouldn't need it)
#=====================================================================================

if [[ "$test_type" == "major" ]] ; then
  mysql_upgrade -uroot
fi

set +e

#=====================================================================================
# Check that the server is functioning and previously created structures are available
#=====================================================================================

# All the commands below should succeed

set -e

mysql -uroot -e "select @@version, @@version_comment"

mysql -uroot -e "SHOW TABLES IN db"
mysql -uroot -e "SELECT * FROM db.t_innodb; INSERT INTO db.t_innodb VALUES (3,'foo'),(4,'bar')"
mysql -uroot -e "SELECT * FROM db.t_myisam; INSERT INTO db.t_myisam VALUES (3,'foo'),(4,'bar')"
mysql -uroot -e "SELECT * FROM db.t_aria; INSERT INTO db.t_aria VALUES (3,'foo'),(4,'bar')"
mysql -uroot -e "SELECT * FROM db.t_memory; INSERT INTO db.t_memory VALUES (1,'foo'),(2,'bar')"
mysql -uroot -e "SELECT COUNT(*) FROM db.v_merge"
mysql -uroot -e "SELECT COUNT(*) FROM db.v_temptable"
mysql -uroot -e "CALL db.p()"
mysql -uroot -e "SELECT db.f()"

set +e

#===================================================================================
# Store information about server version and available plugins/engines after upgrade
#===================================================================================

set -e

mysql -uroot --skip-column-names -e "select @@version" | awk -F'-' '{ print $1 }' > /tmp/version.new
mysql -uroot --skip-column-names -e "select engine, support, transactions, savepoints from information_schema.engines" | sort > /tmp/engines.new

cat /tmp/engines.new

mysql -uroot --skip-column-names -e "select plugin_name, plugin_status, plugin_type, plugin_library, plugin_license from information_schema.all_plugins where plugin_name not in ('DISKS','ROCKSDB_DEADLOCK') order by plugin_name, plugin_library" > /tmp/plugins.new

if [[ "$distro" != "centos6" ]] ; then
  ls -l /usr/lib/systemd/system/mariadb.service
  ls -l /etc/systemd/system/mariadb.service.d/migrated-from-my.cnf-settings.conf
  ls -l /etc/init.d/mysql || true
  systemctl status mariadb.service --no-pager
  systemctl status mariadb --no-pager
# MDEV-19432 - Systemd service does not get re-enabled after upgrade
  sudo systemctl enable mariadb
  systemctl is-enabled mariadb
  systemctl status mysql --no-pager
  systemctl status mysqld --no-pager
fi

set +e

# Until """+DEVELOPMENT_BRANCH+""" is GA, the list of plugins/engines might be unstable, skipping the check
# For major upgrade, no point to do the check at all

if [[ "$test_type" != "major" ]] ; then

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
fi

diff -u /tmp/version.old /tmp/version.new
if [[ $? -eq 0 ]] ; then
  echo "ERROR: server version has not changed after upgrade"
  echo "It can be a false positive if we forgot to bump version after release,"
  echo "or if it is a development tree is based on an old version"
  exit 1
fi
