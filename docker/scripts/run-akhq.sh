#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the AKHQ configuration directory and file
AKHQ_CONFIG_DIR="$SCRIPT_DIR/../service-data/akhq/configs"
AKHQ_CONFIG_FILE="$AKHQ_CONFIG_DIR/application.yml"

# Ensure the configuration directory exists
mkdir -p "$AKHQ_CONFIG_DIR"

# Create the application.yml file with required configurations
cat > "$AKHQ_CONFIG_FILE" <<EOL
akhq:
  connections:
    kafka-cluster-1:
      properties:
        bootstrap.servers: "localhost:9092"
      schema-registry: "http://localhost:8081"
  security:
    default-group: admin
    groups:
      admin:
        roles:
          - topic/read
          - topic/insert
          - topic/delete
          - group/read
          - group/delete
          - node/read
          - topic/config/update
          - group/config/update
          - acls/read
          - acls/update
EOL

# Start Kafka
"$SCRIPT_DIR/run-kafka.sh"

# Verify if Kafka is running
verify_service "kafka"

# Restart AKHQ service if it's not running
restart_service "akhq" "$SCRIPT_DIR/../docker-compose/docker-compose-akhq.yml" "akhq"