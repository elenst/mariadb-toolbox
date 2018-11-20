#!/usr/bin/bash

set -x

df -k
df -k $HOME
cat /proc/cpuinfo | grep -E 'processor|cpu cores|cpu MHz|model name'
top -b -n 1

dpkg -l | grep apport
sudo ps -ef | grep apport

cat /proc/sys/kernel/core_pattern
sudo service apport stop
cat /proc/sys/kernel/core_pattern

set +x
