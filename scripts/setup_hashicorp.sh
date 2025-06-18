#!/usr/bin/env bash

set -x

. /etc/os-release

export VAULT_ADDR='http://127.0.0.1:8200'

if ! [ -e $WORKSPACE/vault.hcl ] ; then
  cat << EOF > $WORKSPACE/vault.hcl
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = 1
}

api_addr = "http://127.0.0.1:8200"

max_lease_ttl = "730h"
default_lease_ttl = "730h"
max_versions=2
ui = true
log_level = "Trace"
EOF

  set -o pipefail

  if [ "${ID}" == "debian" ] || [ "${ID}" == "ubuntu" ] ; then
    sudo apt-get install -y gnupg || true
    for _i in 1 2 3 4 5 ; do
      if curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - ; then break; fi
      sleep 2
    done
    echo "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /tmp/hashicorp.list
    sudo mv /tmp/hashicorp.list /etc/apt/sources.list.d/
    sudo apt-get update -y --allow-releaseinfo-change && sudo apt-get install vault
    sudo cp $WORKSPACE/vault.hcl /etc/vault.d/
  elif [ "${ID}" == "rhel" ] || [ "${ID}" == "rocky" ] || [ "${ID}" == "almalinux" ] || [ "${ID}" == "ol" ] ; then
     vers=`echo $VERSION_ID | awk -F'.' '{print $1}'`
#    sudo yum install -y yum-utils
#    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# According to https://www.hashicorp.com/blog/announcing-the-linux-package-archive-site,
# $releasever (7Server) no longer works, but they keep writing it
    wget -O- https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | sed -e "s/\$releasever/$vers/" | sudo tee /etc/yum.repos.d/hashicorp.repo
    sudo yum -y install vault
    sudo cp $WORKSPACE/vault.hcl /etc/vault.d/
  elif [ "${ID}" == "sles" ] && [[ "${VERSION_ID}" =~ ^12 ]] ; then
    echo "WARNING: Standalone vault doesn't seem to work on SLES 12, skipping it"
    exit 4
  else
    echo "WARNING: Don't know how to install vault on ${ID}, trying a binary"
    vault_arch=`uname -m`
    if [ "$vault_arch" == "x86_64" ] ; then
      vault_arch="amd64"
    elif [ "$vault_arch" == "aarch64" ] ; then
      vault_arch="arm64"
    fi
    sudo wget https://releases.hashicorp.com/vault/1.19.5/vault_1.19.5_linux_${vault_arch}.zip -O /usr/local/bin/vault.zip
    cd /usr/local/bin
    sudo unzip vault.zip
    if ! ./vault --version ; then
      echo "ERROR: Couldn't install vault from a zip file"
      exit 4
    fi
    sudo rm vault.zip
    cd -
  fi
fi

if [ -x /usr/local/bin/vault ] ; then
  sudo /usr/local/bin/vault server --config=$WORKSPACE/vault.hcl &  
elif which vault ; then
  if ! sudo systemctl restart vault ; then
    echo "ERROR: Could not (re)start vault after installation"
    exit 4
  fi
else
  echo "ERROR: vault is not installed"
  exit 4
fi

set -e

if [ -e $WORKSPACE/vault.init ] ; then
  echo "Hashicorp vault was already initialized"
else
  # restart exits too early, vault may be not ready yet
  for i in 1 2 3 4 5 ; do
    sleep 2
    if vault operator init > $WORKSPACE/vault.init ; then
      break
    fi
  done
fi

vault operator unseal `grep 'Unseal Key 1:' $WORKSPACE/vault.init | awk '{ print $4 }'`
vault operator unseal `grep 'Unseal Key 2:' $WORKSPACE/vault.init | awk '{ print $4 }'`
vault operator unseal `grep 'Unseal Key 3:' $WORKSPACE/vault.init | awk '{ print $4 }'`
export VAULT_TOKEN=`grep 'Initial Root Token:' $WORKSPACE/vault.init | awk '{ print $4 }'`

if ! vault login $VAULT_TOKEN ; then
  echo "ERROR: Could not login into the vault"
  exit 4
fi

echo "Checking the vault is working"
if ! vault secrets disable mariadbtest && \
      vault secrets enable -path /mariadbtest -version=2 kv &&
      vault kv put /mariadbtest/1 data="123456789ABCDEF0123456789ABCDEF0" &&
      vault secrets disable mariadbtest
then
  echo "ERROR: Vault is not functioning properly after installation"
  exit 4
fi
