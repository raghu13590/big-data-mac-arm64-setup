#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart Flink Job Manager service if it's not running
restart_service "jobmanager" "$SCRIPT_DIR/../docker-compose/docker-compose-flink.yml" "flink-jobmanager"

# Restart Flink Task Manager service if it's not running
restart_service "taskmanager" "$SCRIPT_DIR/../docker-compose/docker-compose-flink.yml" "flink-taskmanager"