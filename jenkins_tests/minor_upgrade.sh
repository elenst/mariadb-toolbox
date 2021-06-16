#!/usr/bin/env bash
#
# Copyright (c) 2021, MariaDB Corporation
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1335  USA

# Expected variables:
# REPOSITORY
# GIT_BRANCH
# ESTOKEN
# label - debian-10, rhel-7-arm etc.

set -xe

##############
# Environment
##############

VERSION=`echo ${GIT_BRANCH} | sed -e 's/.*\(10\.[2-9]\).*/\\1/'`
PKGS=$(cat pkglist.txt | sed -e 's/\(mariadb-plugin-connect\|MariaDB-connect-engine\|mariadb-plugin-mroonga\|mariadb-plugin-columnstore\|mariadb-test\|mariadb-test-data\)//gi')
export DEBIAN_FRONTEND=noninteractive
#export MYSQL_PASSWORD='tESt123%_password'
case ${VERSION} in
  *10.[2-3]*)
    GALERA_VERSION=3
    client_command=mysql
    ;;
  *10.[4-9]*)
    GALERA_VERSION=4
    client_command=mariadb
    ;;
  *)
    echo "ERROR: Unknown version ${VERSION} extracted from branch ${GIT_BRANCH}"
    exit 1
esac
  
case ${label} in
  rhel*|sles*)
    PKG_TYPE=RPM
    package_list_command="rpm -qa"
    if [[ ${label} =~ "rhel" ]] ; then
      if [[ ${label} =~ "rhel-7" ]] ; then
        PKG_MNG=yum
      else
        PKG_MNG=dnf
      fi
      install_command="${PKG_MNG} -y install"
      upgrade_command="${PKG_MNG} -y upgrade"
      repo_update_command="${PKG_MNG} clean all"
      repo_location=/etc/yum.repos.d/
      if [[ ${label} =~ rhel-8 ]]; then
        RHEL8FIX='module_hotfixes=true'
      fi
    else
      install_command="zypper -n install"
      upgrade_command="zypper -n --no-gpg-checks install"
      repo_update_command="zypper clean --all"
      repo_location=/etc/zypp/repos.d/
    fi
    ;;
  *debian*|*ubuntu*)
    PKG_TYPE=DEB
    install_command="apt-get -y install"
    upgrade_command="apt-get -y install"
    repo_update_command="apt-get update"
    package_list_command="dpkg -l"
    repo_location=/etc/apt/sources.list.d/
    ;;
  *)
    echo "ERROR: Unknown label ${label}"
    exit 1
esac


##############
# Workarounds
##############

# TODO: Find out if it's really needed, it shouldn't even be installed on the build machine
if [[ ${label} =~ debian-9 ]] ; then sudo ${install_command} -t stretch-backports rocksdb-tools; fi
# TODO: Remove when MENT-1229 is fixed
if [[ ${label} =~ rhel-8 ]] && [[ ${VERSION} =~ 10.2 ]] ; then sudo dnf -y erase mariadb-connector-c ; fi

#########################
# Functions and commands
#########################

# Expects a command as an argument
retry()
{
  for i in 1 2 3 4; do $1 && return || sleep 1; done
  # Last attempt is separate to avoid extra sleep
  $1
}

# TODO: It needs to be modified anyway, so I won't clean it up now
# Expects "old" or "new" as an argument
collect_dependencies()
{
  set +x
  echo "Collecting dependencies for the $1 server"
  if [ ${PKG_TYPE} == "DEB" ] ; then
    for i in `sudo which mysqld | sed -e 's/mysqld$/mysql\*/'` `which mysql | sed -e 's/mysql$/mysql\*/'` `dpkg-query -L \`dpkg -l | grep mariadb | awk '{print $2}' | xargs\` | grep -v 'mysql-test' | grep -v '/debug/' | grep '/plugin/' | sed -e 's/[^\/]*$/\*/' | sort | uniq | xargs` ; do
      echo "=== $i"
      ldd $i | sort | sed 's/(.*)//'
    done > ./ldd.$1
    sudo apt-cache depends ${PKGS} --no-recommends --no-conflicts --no-breaks --no-replaces > ./reqs.$1
  else
    for i in `sudo which mysqld | sed -e 's/mysqld$/mysql\*/'` `which mysql | sed -e 's/mysql$/mysql\*/'` `rpm -ql \`rpm -qa | grep MariaDB | xargs\` | grep -v 'mysql-test' | grep -v '/debug/' | grep '/plugin/' | sed -e 's/[^\/]*$/\*/' | sort | uniq | xargs`; do
      echo "=== $i"
      ldd $i | sort | sed 's/(.*)//'
    done > ./ldd.$1
    for p in ${PKGS} ; do
      echo "$p:"
      # GLIBCXX_3.4.14 is a workaround for a Columnstore change in June release set
      rpm -q -R $p | awk '{print $1}' | grep -v 'GLIBCXX_3.4.14'
      echo ""
    done > ./reqs.$1
  fi
  set -x
}

configure_test_repo()
{
  sudo rm -f ${repo_location}/mariadb.*
  if [ ${PKG_TYPE} == "DEB" ] ; then
    echo "deb [trusted=yes] http://repo/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/apt ${label}/" > enterprise-server.list
    echo "deb [trusted=yes] ${REPOSITORY} ${label}/" >> enterprise-server.list
    cat enterprise-server.list
    sudo mv -vf enterprise-server.list ${repo_location}
  else
    repo_file=enterprise.repo
    if [[ ${label} =~ rhel ]] ; then
      cat << EOF > enterprise.repo
[es-server-${VERSION}]
name=MariaDB-ES
baseurl=${REPOSITORY}
gpgcheck=0
${RHEL8FIX:-}
EOF
    cat enterprise.repo
    sudo mv -vf enterprise.repo ${repo_location}
    elif [[ ${label} =~ sles ]] ; then
      sudo zypper ar -f -g http://repo/jenkins/DEVBUILDS/galera-${GALERA_VERSION}/latest/rpm/${label} Galera-Enterprise
      sudo zypper ar -f ${REPOSITORY} MariaDB-Enterprise
    fi
  fi
  sudo ${repo_update_command}
}

##############
# Main
##############

${package_list_command} | grep -Ei 'mariadb|mysql|galera' || true

# Installing the old server

retry "wget https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup"
chmod +x mariadb_es_repo_setup

#retry "sudo ${install_command} debconf-utils"

sudo ./mariadb_es_repo_setup --token="${ESTOKEN}" --apply --mariadb-server-version="${VERSION}" --skip-maxscale
retry "sudo ${repo_update_command}"

# Workaround for MDEV-25930
if [ "${PKG_TYPE}" == "RPM" ] ; then
  set +e
fi
sudo ${install_command} ${PKGS}
# Workaround for MDEV-25930
if [ "${PKG_TYPE}" == "RPM" ] ; then
  set -e
fi
sudo systemctl restart mariadb

echo 'SELECT VERSION()' | sudo ${client_command} | tee /tmp/version.old
collect_dependencies "old"

# Installing the new server

configure_test_repo

# Workaround for MDEV-25930
if [ "${PKG_TYPE}" == "RPM" ] ; then
  set +e
fi
sudo ${upgrade_command} ${PKGS}
# Workaround for MDEV-25930
if [ "${PKG_TYPE}" == "RPM" ] ; then
  set -e
fi
sudo systemctl restart mariadb || journalctl -xe | tail -n 100 && systemctl status mariadb.service 

echo 'SELECT VERSION()' | sudo ${client_command} | tee /tmp/version.new
collect_dependencies "new"

# If we are still here, nothing has failed yet
res=0
if diff /tmp/version.old /tmp/version.new ; then
  echo "ERROR: Server version has not changed after upgrade" >> ./errors
  res=1
fi
if diff -U1000 ./ldd.old ./ldd.new | grep -E '^[-+]\s|^ =' ; then
  # Inner if is a workaround for an intentional change in June release set for libpthread; remove after the release
  if diff -U1000 ./ldd.old ./ldd.new | grep -v libpthread | grep -E '^[-+]\s' ; then
    echo "ERROR: found changes in ldd output on installed binaries" >> ./errors
    res=1
  fi
fi
if ! diff -U150 ./reqs.old ./reqs.new ; then
  echo "ERROR: found changes in package requirements" >> ./errors
  res=1
fi

if [ "$res" != "0" ] ; then
  cat ./errors
fi

exit $res
