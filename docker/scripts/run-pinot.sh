#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart Pinot services individually if they are not running
restart_service "pinot-controller" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-controller"
restart_service "pinot-broker" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-broker"
restart_service "pinot-server" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-server"