#!/bin/bash

# Expects: 
# - HOME (mandatory)
# - SRCDIR (mandatory)
# - SERVER_BRANCH_OPTION (optional)

cd $HOME

set -x

git clone https://github.com/MariaDB/server --depth=1 $SERVER_BRANCH_OPTION $SRCDIR
cd $SRCDIR
git log -1

set +x

cd $HOME
