#!/bin/bash

# This script is now really pointless, but too many Travis branches call it,
# so it's easier to keep it than modify all travis configs

# Expects
# - TOOLBOX_DIR (mandatory)

cd $HOME

set -x

. $TOOLBOX_DIR/travis/setup_environment.sh
. $SCRIPT_DIR/clone_server.sh

set +x

cd $HOME
