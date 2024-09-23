#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart Spark services if they are not running
restart_service "spark-master" "$SCRIPT_DIR/../docker-compose/docker-compose-spark.yml" "spark-master"
restart_service "spark-worker-1" "$SCRIPT_DIR/../docker-compose/docker-compose-spark.yml" "spark-worker-1"
restart_service "spark-worker-2" "$SCRIPT_DIR/../docker-compose/docker-compose-spark.yml" "spark-worker-2"

echo "All services are up and running!"

# Run Spark tests
"$SCRIPT_DIR/test-spark.sh"