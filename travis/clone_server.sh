#!/bin/bash

# Expects: 
# - HOME (mandatory)
# - SRCDIR (mandatory)
# - SERVER_BRANCH_OPTION (optional)
# - SERVER_REVISION (optional)

cd $HOME

set -x

if [ -z "$SERVER_REVISION" ] ; then
  git clone https://github.com/MariaDB/server --depth=1 $SERVER_BRANCH_OPTION $SRCDIR
  cd $SRCDIR
else
  git clone https://github.com/MariaDB/server $SERVER_BRANCH_OPTION $SRCDIR
  cd $SRCDIR
  git checkout $SERVER_REVISION
fi
git log -1

set +x

cd $HOME
