#!/bin/bash

if [ $# -lt 3 ] ; then
  echo "Usage: $0 <remote repo> <local repo location> <branch ...>"
  exit 1
fi

remote_repo=$1
local_repo=$2
shift 2
branches=$*
echo
date
echo
echo "Checking branches $* for updates"
for b in $branches ; do
    echo
    cd $local_repo
    remote_rev=`git ls-remote $remote_repo $b | grep heads | cut -c 1-8`
    if [ -e $b ] ; then
        cd $b
        git reset --hard HEAD
        git clean -dfx
        git submodule foreach --recursive git clean -xdf
        git checkout $b
        git submodule init
        git submodule update
        local_rev=`git log -1 --abbrev=8 --pretty="%h"`
        echo "For branch $b: local revision $local_rev, remote revision $remote_rev"
        if [ "$local_rev" != "$remote_rev" ] ; then
            git pull --ff-only
            if [ $? -ne 0 ] ; then
                echo "Branches apparently diverged, re-cloning"
                cd $local_repo
                rm -rf $b
                git clone $remote_repo --branch $b $b
            else
                echo "Fast-forward was successful"
                git submodule update
            fi
        else
            echo "Revisions are identical, no need to update"
        fi
    else
        echo "Branch $b doesn't exist, cloning"
        git clone $remote_repo --branch $b $b
    fi
done
