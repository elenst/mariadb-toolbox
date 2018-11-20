#!/usr/bin/bash

set -x

df -k
df -k $HOME
cat /proc/cpuinfo | grep -E 'processor|cpu cores|cpu MHz|model name'
top -b -n 1

sudo sh -c "echo core > /proc/sys/kernel/core_pattern"

set +x
