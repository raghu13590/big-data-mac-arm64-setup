#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Source run-hdfs.sh
source "$SCRIPT_DIR/run-hdfs.sh"

start_yarn() {
  # Restart YARN ResourceManager if it's not running
  restart_service "yarn-resourcemanager" "$SCRIPT_DIR/../docker-compose/docker-compose-yarn.yml" "yarn-resourcemanager"

  # Restart YARN NodeManager if it's not running
  restart_service "yarn-nodemanager-1" "$SCRIPT_DIR/../docker-compose/docker-compose-yarn.yml" "yarn-nodemanager-1"

  # Optional: If you have multiple NodeManagers, restart the others as well
  restart_service "yarn-nodemanager-2" "$SCRIPT_DIR/../docker-compose/docker-compose-yarn.yml" "yarn-nodemanager-2"
}

# Restart Zookeeper if it's not running
restart_service "zookeeper" "$SCRIPT_DIR/../docker-compose/docker-compose-zookeeper.yml" "zookeeper"
verify_service "zookeeper"

# Restart HDFS NameNode if it's not running
start_hdfs

# Start YARN
start_yarn