#!/bin/bash

# This script is used to set up and run a Hadoop cluster using Docker Compose.
# It builds the Hadoop Docker image, formats the NameNode if necessary, and starts
# the Hadoop services in the correct order. Additionally, it can perform a clean
# install if the "--reset" parameter is provided.

# Usage:
# ./run-hadoop.sh [--reset]
# - If "--reset" is provided as an argument, the script will perform a clean install.
# - If no argument is provided, the script will start the Hadoop services without
#   resetting the environment.

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
HADOOP_COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-hadoop.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../dockerfile/hadoop"
ZOOKEEPER_HADOOP_COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-zookeeper.yml"
APP_DATA_DIR="$SCRIPT_DIR/../app-data"

# Build the Hadoop image
echo "Building Hadoop image..."
docker build -t hadoop:3.3.6 "$DOCKERFILE_DIR"

# Function to reset the metastore schema
reset_metastore_schema() {
    local reset=$1
    echo "Resetting metastore schema..."
    if [ "$(docker-compose -f "$HADOOP_COMPOSE_FILE" exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then
        echo "Initializing metastore schema..."
        docker-compose -f "$HADOOP_COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
    elif [ "$reset" == "reset" ]; then
        echo "Dropping and recreating metastore schema..."
        docker-compose -f "$HADOOP_COMPOSE_FILE" exec metastore sh -c 'PGPASSWORD=hive psql -U hive -d metastore -h postgres -p 5432 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"'
        docker-compose -f "$HADOOP_COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
    else
        echo "Metastore schema already exists. Skipping initialization."
    fi
}

# Function to perform clean install
perform_clean_install() {
    echo "Performing absolute clean install..."

    # Stop all containers and remove volumes
    echo "Stopping all containers and removing volumes..."
    docker-compose -f "$HADOOP_COMPOSE_FILE" down -v

    SERVICES=$(docker-compose -f "$HADOOP_COMPOSE_FILE" config --services)
    # Clear all service-related data
    for service in "${SERVICES[@]}"; do
        echo "Clearing $service data..."
        find "$APP_DATA_DIR/$service" -mindepth 1 -delete
    done

    # Format NameNode
    echo "Formatting NameNode..."
    docker-compose -f "$HADOOP_COMPOSE_FILE" run --rm namenode hdfs namenode -format -force

    echo "Absolute clean install completed."
}

# Start Zookeeper
"$SCRIPT_DIR/run-zookeeper.sh"

# Perform clean install if reset parameter is provided
if [ "$RESET_PARAM" == "reset" ]; then
    perform_clean_install
fi

# Start the Hadoop services in order
echo "Starting Hadoop services..."

# Start NameNode
restart_service "namenode" $HADOOP_COMPOSE_FILE "namenode"

# Reset Hive warehouse directory
if [ "$RESET_PARAM" == "reset" ]; then
    echo "Resetting Hive warehouse directory..."
    docker-compose -f "$HADOOP_COMPOSE_FILE" exec namenode hdfs dfs -rm -r /user/hive/warehouse
    docker-compose -f "$HADOOP_COMPOSE_FILE" exec namenode hdfs dfs -mkdir -p /user/hive/warehouse
    docker-compose -f "$HADOOP_COMPOSE_FILE" exec namenode hdfs dfs -chmod g+w /user/hive/warehouse
fi

# Start DataNodes
restart_service "datanode1" $HADOOP_COMPOSE_FILE "datanode1"
restart_service "datanode2" $HADOOP_COMPOSE_FILE "datanode2"

# Start ResourceManager
restart_service "resourcemanager" $HADOOP_COMPOSE_FILE "resourcemanager"

# Start NodeManagers
restart_service "nodemanager1" $HADOOP_COMPOSE_FILE "nodemanager1"
restart_service "nodemanager2" $HADOOP_COMPOSE_FILE "nodemanager2"

# Start Hive
restart_service "postgres" $HADOOP_COMPOSE_FILE "postgres"
restart_service "metastore" $HADOOP_COMPOSE_FILE "metastore"
reset_metastore_schema $RESET_PARAM
restart_service "hiveserver2" $HADOOP_COMPOSE_FILE "hiveserver2"

echo "All services are up and running!"

# Run the test script
"$SCRIPT_DIR/tests/test-hadoop.sh"