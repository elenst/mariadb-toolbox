#!/usr/bin/bash

set -x

df -k
df -k $HOME
cat /proc/cpuinfo | grep -E 'processor|cpu cores|cpu MHz|model name'
top -b -n 1

set +x