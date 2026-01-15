#!/usr/bin/env bash

set -x

: "${WORKSPACE:=$HOME}"
. /etc/os-release

if ! [ -x $WORKSPACE/bao/bao ] ; then

  vault_arch=`uname -m`
  case $vault_arch in
  x86_64|ppc64le|s390x)
    ;;
  aarch64)
    vault_arch='arm64'
    ;;
  *)
    echo "ERROR: Unexpected architecture $vault_arch"
    exit 4
    ;;
  esac

  mkdir $WORKSPACE/bao
  cd $WORKSPACE/bao
  rm -rf *

  wget -nv https://github.com/openbao/openbao/releases/download/v2.4.4/bao_2.4.4_Linux_${vault_arch}.tar.gz -O bao.tar.gz
  tar zxf bao.tar.gz
  ln -s ./bao ./vault
  cd -
fi

export PATH="$WORKSPACE/bao:$PATH"
unset VAULT_TOKEN

vault server -dev > $WORKSPACE/bao/bao.log 2>&1 &
# Let it initialize
for i in 1 2 3 4 5 6 7 8 9 ; do
  if grep 'Root Token: ' $WORKSPACE/bao/bao.log ; then
    export VAULT_TOKEN=`grep 'Root Token: ' $WORKSPACE/bao/bao.log | sed -e 's/^.*Root Token: //'`
    break
  fi
  sleep 1
done

if [ -z "$VAULT_TOKEN" ] ; then
  echo "ERROR: Could not initialize vault"
  cat $WORKSPACE/bao/bao.log
  exit 4
fi

export VAULT_ADDR='http://127.0.0.1:8200'
