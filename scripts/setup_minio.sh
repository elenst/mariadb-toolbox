#!/usr/bin/env bash

set -x

minio_arch=`uname -m`
if [ "$minio_arch" == "x86_64" ] ; then
  minio_arch=amd64
elif [ "$minio_arch" == "aarch64" ] ; then
  minio_arch=arm64
else
  echo "ERROR: Architecture $minio_arch is not supported"
  exit 4
fi

# Server
for _i in 1 2 3 4 5 ; do
  if wget -nv https://dl.min.io/server/minio/release/linux-${minio_arch}/minio -O ${WORKSPACE}/minio ; then
    if [ -e ${WORKSPACE}/minio ] ; then
      chmod +x ${WORKSPACE}/minio
      break
    fi
  fi
  sleep 3
done

if ! [ -x ${WORKSPACE}/minio ] ; then
  echo "ERROR: Could not download minio server"
  exit 4
fi

export MINIO_ROOT_USER=minio
export MINIO_ROOT_PASSWORD=minioadmin

MINIO_ROOT_USER=minio MINIO_ROOT_PASSWORD=minioadmin ${WORKSPACE}/minio server ${WORKSPACE}/minio-data 2>&1 &

# Client
for _i in 1 2 3 4 5 ; do
  if wget -nv https://dl.min.io/client/mc/release/linux-${minio_arch}/mc -O ${WORKSPACE}/mc ; then
    if [ -e ${WORKSPACE}/mc ] ; then
      chmod +x ${WORKSPACE}/mc
      break
    fi
  fi
  sleep 3
done

if ! [ -x ${WORKSPACE}/mc ] ; then
  echo "ERROR: Could not download minio client"
  exit 4
fi

# Try a few times in case the server in the background hasn't finished initializing yet
res=4
for _i in 1 2 3 4 5 ; do
  if ${WORKSPACE}/mc alias set local http://127.0.0.1:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD} ; then
    res=0
    break
  fi
  sleep 3
done
if [ "$res" != "0" ] ; then
  echo "ERROR: Couldn't configure MinIO server"
  exit 4
fi

if ! ${WORKSPACE}/mc mb --ignore-existing local/storage-engine ; then
  echo "ERROR: Couldn't setup MinIO"
  exit 4
fi
