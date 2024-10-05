#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the path to the Docker Compose file
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-hadoop.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../dockerfile/hadoop"

# Check if Docker is running
check_docker_running

# Validate the Docker Compose file
validate_compose_file "$COMPOSE_FILE"

# Build the Hadoop image
echo "Building Hadoop image..."
docker build -t hadoop:3.3.6 "$DOCKERFILE_DIR"

# Function to format the NameNode
format_namenode() {
    echo "Formatting NameNode..."
    docker-compose -f "$COMPOSE_FILE" run --rm namenode hdfs namenode -format
}

# Function to initialize the metastore schema
initialize_metastore_schema() {
    echo "Initializing metastore schema..."
    docker-compose -f "$COMPOSE_FILE" exec metastore $HIVE_HOME/bin/schematool -dbType postgres -initSchema
}

# Function to drop and recreate the metastore schema
drop_and_recreate_metastore_schema() {
    echo "Dropping and recreating metastore schema..."
    docker-compose -f "$COMPOSE_FILE" exec metastore $HIVE_HOME/bin/schematool -dbType postgres -dropSchema
    docker-compose -f "$COMPOSE_FILE" exec metastore $HIVE_HOME/bin/schematool -dbType postgres -initSchema
}

# Function to start and verify a service
start_and_verify_service() {
    local service_name="$1"
    echo "Starting $service_name..."
    docker-compose -f "$COMPOSE_FILE" up -d "$service_name"
    verify_service "$service_name"
}

# Check if NameNode needs formatting
if [ ! -f "$SCRIPT_DIR/../app-data/hadoop/namenode/current/VERSION" ]; then
    format_namenode
fi

# Start the Hadoop services in order
echo "Starting Hadoop services..."

# Start NameNode
start_and_verify_service "namenode"

# Start DataNodes
start_and_verify_service "datanode1"
start_and_verify_service "datanode2"

# Start ResourceManager
start_and_verify_service "resourcemanager"

# Start NodeManagers
start_and_verify_service "nodemanager1"
start_and_verify_service "nodemanager2"

# Start Hive
# Check if PostgreSQL data directory is empty
if [ ! "$(ls -A $SCRIPT_DIR/../app-data/postgres)" ]; then
    initialize_metastore_schema
else
    drop_and_recreate_metastore_schema
fi
start_and_verify_service "postgres"
start_and_verify_service "metastore"
start_and_verify_service "hiveserver2"

echo "All services are up and running!"

# Run the test script
"$SCRIPT_DIR/tests/test-hadoop.sh"