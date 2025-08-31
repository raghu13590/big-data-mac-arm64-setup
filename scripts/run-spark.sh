#!/bin/bash
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the path to the Docker Compose file
COMPOSE_FILE="$SCRIPT_DIR/../apps/spark/docker-compose-spark.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../apps/spark"

# Check if Docker is running
check_docker_running

# Validate the Docker Compose file
validate_compose_file "$COMPOSE_FILE"

# Build the Spark image
echo "Building Spark image..."
docker build -t spark-local "$DOCKERFILE_DIR"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Restart Spark services if they are not running
restart_service "spark-master" "$COMPOSE_FILE" "spark-master"
restart_service "spark-history" "$COMPOSE_FILE" "spark-history"
restart_service "spark-worker-1" "$COMPOSE_FILE" "spark-worker-1"
restart_service "spark-worker-2" "$COMPOSE_FILE" "spark-worker-2"

echo "All services are up and running!"

# Run Spark tests
"$SCRIPT_DIR/tests/test-spark.sh"
