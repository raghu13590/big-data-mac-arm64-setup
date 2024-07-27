#!/bin/bash

# Source common functions
source ./scripts/common-functions.sh

# Create Docker network if it doesn't exist
if ! docker network ls | grep "big-data-network" > /dev/null; then
    echo "Creating Docker network big-data-network..."
    docker network create big-data-network
else
    echo "Docker network big-data-network already exists."
fi

# Remove orphaned containers
remove_orphans "docker-compose/docker-compose-zookeeper.yml"

# Check if Zookeeper is already running
if is_running "zookeeper"; then
    echo "Zookeeper is already running."
else
    echo "Starting Zookeeper..."
    docker-compose -f docker-compose/docker-compose-zookeeper.yml up -d
    verify_service "zookeeper"
fi