#!/usr/bin/bash

set -x

df -k
df -k $HOME
cat /proc/cpuinfo
top -b -n 1

set +x
