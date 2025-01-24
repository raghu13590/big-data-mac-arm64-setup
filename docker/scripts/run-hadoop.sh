#!/bin/bash

# This script is used to set up and run a Hadoop cluster using Docker Compose.
# It builds the Hadoop Docker image, formats the NameNode if necessary, and starts
# the Hadoop services in the correct order. Additionally, it can reset the metastore
# schema if the "--reset" parameter is provided.

# Usage:
# ./run-hadoop.sh [--reset]
# - If "--reset" is provided as an argument, the script will reset the metastore schema
#   and format the NameNode.
# - If no argument is provided, the script will start the Hadoop services without
#   resetting the metastore schema or formatting the NameNode.

# Check for the reset parameter
RESET_PARAM=""
if [ "$1" == "--reset" ]; then
    RESET_PARAM="reset"
elif [ -n "$1" ]; then
    echo "Error: Unrecognized parameter '$1'"
    echo "Usage: $0 [--reset]"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the path to the Docker Compose file
COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-hadoop.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../dockerfile/hadoop"

# Build the Hadoop image
echo "Building Hadoop image..."
docker build -t hadoop:3.3.6 "$DOCKERFILE_DIR"

# Function to reset the metastore schema
reset_metastore_schema() {
    local reset=$1
    echo "Resetting metastore schema..."
    if [ "$(docker-compose -f "$COMPOSE_FILE" exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then
        echo "Initializing metastore schema..."
        docker-compose -f "$COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
    elif [ "$reset" == "reset" ]; then
        echo "Dropping and recreating metastore schema..."
        docker-compose -f "$COMPOSE_FILE" exec metastore sh -c 'PGPASSWORD=hive psql -U hive -d metastore -h postgres -p 5432 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"'
        docker-compose -f "$COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
    else
        echo "Metastore schema already exists. Skipping initialization."
    fi
}

# Format the NameNode if it has not been formatted or if reset parameter is provided
if [ ! -f "$SCRIPT_DIR/../app-data/hadoop/namenode/current/VERSION" ] || [ "$RESET_PARAM" == "reset" ]; then
    echo "Formatting NameNode..."
    docker-compose -f "$COMPOSE_FILE" run --rm namenode hdfs namenode -format
fi

# Start the Hadoop services in order
echo "Starting Hadoop services..."

# Start NameNode
restart_service "namenode" $COMPOSE_FILE "namenode"

# Start DataNodes
restart_service "datanode1" $COMPOSE_FILE "datanode1"
restart_service "datanode2" $COMPOSE_FILE "datanode2"

# Start ResourceManager
restart_service "resourcemanager" $COMPOSE_FILE "resourcemanager"

# Start NodeManagers
restart_service "nodemanager1" $COMPOSE_FILE "nodemanager1"
restart_service "nodemanager2" $COMPOSE_FILE "nodemanager2"

# Start Hive
restart_service "postgres" $COMPOSE_FILE "postgres"
restart_service "metastore" $COMPOSE_FILE "metastore"
reset_metastore_schema $RESET_PARAM
restart_service "hiveserver2" $COMPOSE_FILE "hiveserver2"

echo "All services are up and running!"

# Run the test script
"$SCRIPT_DIR/tests/test-hadoop.sh"