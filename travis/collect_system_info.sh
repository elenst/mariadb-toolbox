#!/usr/bin/bash

set -x

df -k
df -k $HOME
cat /proc/cpuinfo | grep -E 'processor|cpu cores|cpu MHz|model name'
top -b -n 1

dpkg -l | grep apport
ps -ef | grep apport

cat /proc/sys/kernel/core_pattern
service apport stop
cat /proc/sys/kernel/core_pattern
echo "core" > /proc/sys/kernel/core_pattern
cat /proc/sys/kernel/core_pattern

set +x
