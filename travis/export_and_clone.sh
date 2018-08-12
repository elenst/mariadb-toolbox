#!/usr/bin/bash

# Expects: 
# - TOOLBOX_DIR (mandatory)
# - HOME (mandatory)
# - SERVER_BRANCH (optional)
# - RQG_BRANCH (optional)

cd $HOME

set -x

export JOB_START=`date '+%s'`
export JOB_END=$((JOB_START + 45*60))
export SCRIPT_DIR=$TOOLBOX_DIR/travis
export SRCDIR=$HOME/src
export BASEDIR=$HOME/server
export RQG_HOME=$HOME/rqg
export RQG_BRANCH="${RQG_BRANCH_OVERRIDE:-$RQG_BRANCH}"
export SERVER_BRANCH="${SERVER_BRANCH_OVERRIDE:-$SERVER_BRANCH}"
export LOGDIR=$HOME/logs
mkdir $LOGDIR
if [ -n "$SERVER_BRANCH" ] ; then SERVER_BRANCH_OPTION="--branch $SERVER_BRANCH" ; fi
if [ -n "$RQG_BRANCH" ] ; then RQG_BRANCH_OPTION="--branch $RQG_BRANCH" ; fi

git clone https://github.com/MariaDB/server --depth=1 $SERVER_BRANCH_OPTION $SRCDIR
git clone https://github.com/elenst/rqg --depth=1 $RQG_BRANCH_OPTION $RQG_HOME
cd $RQG_HOME
export RQG_REVISION=`git log -1 --pretty="%H"`
echo $RQG_REVISION
cd $TOOLBOX_DIR
git log -1
cd $SRCDIR
git log -1

set +x

cd $HOME
