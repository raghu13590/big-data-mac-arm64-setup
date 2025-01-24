#!/bin/bash

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

# Function to format the NameNode
format_namenode() {
    echo "Formatting NameNode..."
    docker-compose -f "$COMPOSE_FILE" run --rm namenode hdfs namenode -format
}

# Function to initialize the metastore schema
initialize_metastore_schema() {
    echo "Initializing metastore schema..."
    docker-compose -f "$COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
}

# Function to drop and recreate the metastore schema
drop_and_recreate_metastore_schema() {
    echo "Dropping and recreating metastore schema..."
    docker-compose -f "$COMPOSE_FILE" exec metastore sh -c 'PGPASSWORD=hive psql -U hive -d metastore -h postgres -p 5432 -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"'
    docker-compose -f "$COMPOSE_FILE" exec metastore sh -c '$HIVE_HOME/bin/schematool -dbType postgres -initSchema'
}

# Check if NameNode needs formatting
if [ ! -f "$SCRIPT_DIR/../app-data/hadoop/namenode/current/VERSION" ]; then
    format_namenode
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

# Check if PostgreSQL data directory is empty
if [ "$(docker-compose -f "$COMPOSE_FILE" exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then
    initialize_metastore_schema
else
    drop_and_recreate_metastore_schema
fi

restart_service "hiveserver2" $COMPOSE_FILE "hiveserver2"

echo "All services are up and running!"

# Run the test script
"$SCRIPT_DIR/tests/test-hadoop.sh"