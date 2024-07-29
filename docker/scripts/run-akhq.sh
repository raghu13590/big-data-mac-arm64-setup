#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Start Kafka
"$SCRIPT_DIR/run-kafka.sh"

# Verify if Kafka is running
verify_service "kafka"

# Restart AKHQ service if it's not running
restart_service "akhq" "$SCRIPT_DIR/../docker-compose/docker-compose-akhq.yml" "akhq"