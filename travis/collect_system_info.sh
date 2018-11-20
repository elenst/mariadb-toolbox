#!/usr/bin/bash

set -x

df -kT
df -k $HOME
cat /proc/cpuinfo | grep -E 'processor|cpu cores|cpu MHz|model name'
top -b -n 1
dpkg -l
ps -ef

set +x
