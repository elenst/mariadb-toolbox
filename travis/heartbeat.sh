#!/usr/bin/bash

export STOPFILE=$HOME/stopit

while [ ! -e $STOPFILE ]
do
  sleep 300
  echo 'Heartbeat'
done
