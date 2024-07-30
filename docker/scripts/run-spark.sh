#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Start Kafka
"$SCRIPT_DIR/run-kafka.sh"

# Verify if Kafka is running
verify_service "kafka"

# Restart Spark services if they are not running
restart_service "spark-master" "$SCRIPT_DIR/../docker-compose/docker-compose-spark.yml" "spark-master"
restart_service "spark-worker" "$SCRIPT_DIR/../docker-compose/docker-compose-spark.yml" "spark-worker"