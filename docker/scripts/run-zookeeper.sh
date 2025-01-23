#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the path to the Docker Compose file
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-zookeeper.yml"

# Create directories if they do not exist
mkdir -p "$SCRIPT_DIR/../app-data/zookeeper/1/data"
mkdir -p "$SCRIPT_DIR/../app-data/zookeeper/2/data"

# Create the myid files
echo "1" > "$SCRIPT_DIR/../app-data/zookeeper/1/data/myid"
echo "2" > "$SCRIPT_DIR/../app-data/zookeeper/2/data/myid"

# Restart Zookeeper if it's not running
restart_service "zookeeper1" "$COMPOSE_FILE" "zookeeper1"
restart_service "zookeeper2" "$COMPOSE_FILE" "zookeeper2"