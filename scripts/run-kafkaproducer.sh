#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the Docker Compose file path
COMPOSE_FILE="$SCRIPT_DIR/../apps/kafkaproducer/docker-compose-kafkaproducer.yml"

# Define the service name
SERVICE_NAME="kafkaproducer"

# Define the path for the sample message file
MESSAGE_DIR="$SCRIPT_DIR/../app-data/kafkaproducer/messages"
MESSAGE_FILE="$MESSAGE_DIR/samplemessage.txt"

# Create sample message file
create_sample_message() {
    mkdir -p "$MESSAGE_DIR"
    echo "sample message at <timestamp> with id : <id>" > "$MESSAGE_FILE"
    echo "Created sample message file: $MESSAGE_FILE"
}

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-kafka.sh"

# Verify if Zookeeper is running
verify_service "kafka"

# Function to build and restart the Kafka producer service
build_and_restart_service() {
    local service_name="$1"
    local compose_file="$2"

    echo -e "\n$(timestamp) [INFO] Building the $service_name image..."
    docker-compose -f "$compose_file" build "$service_name"

    echo -e "\n$(timestamp) [INFO] Restarting $service_name to apply updates..."
    docker-compose -f "$compose_file" up -d --force-recreate "$service_name"

    # Verify if the service is running and healthy
    verify_service "$service_name"
}

# Create the sample message file
create_sample_message

# Build and restart the Kafka producer service
build_and_restart_service "$SERVICE_NAME" "$COMPOSE_FILE"