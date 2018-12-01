#!/bin/bash

# This script is now really pointless, but too many Travis branches call it,
# so it's easier to keep it than modify all travis configs

cd $HOME

set -x

. $SCRIPT_DIR/setup_environment.sh
. $SCRIPT_DIR/clone_server.sh

set +x

cd $HOME
