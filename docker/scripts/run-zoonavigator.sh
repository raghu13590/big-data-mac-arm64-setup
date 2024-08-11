#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart ZooNavigator service
restart_service "zoonavigator" "$SCRIPT_DIR/../docker-compose/docker-compose-zoonavigator.yml" "zoonavigator"

# Verify if ZooNavigator is running and healthy
verify_service "zoonavigator"