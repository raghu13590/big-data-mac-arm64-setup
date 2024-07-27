#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Restart Zookeeper if it's not running
restart_service "zookeeper" "$SCRIPT_DIR/../docker-compose/docker-compose-zookeeper.yml" "zookeeper"