#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the path to the Docker Compose file
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-flink.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../dockerfile/flink"

# Check if Docker is running
check_docker_running

# Validate the Docker Compose file
validate_compose_file "$COMPOSE_FILE"

# Build the Flink image
echo "Building Flink image..."
docker build -t flink-local "$DOCKERFILE_DIR"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Restart Flink Job Manager service if it's not running
restart_service "jobmanager" "$COMPOSE_FILE" "flink-jobmanager"

# Restart Flink Task Manager service if it's not running
restart_service "taskmanager" "$COMPOSE_FILE" "flink-taskmanager"

echo "All services are up and running!"

# Run Flink tests
"$SCRIPT_DIR/tests/test-flink.sh"