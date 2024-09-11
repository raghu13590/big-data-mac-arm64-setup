#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Define the directories to be created
HADOOP_DATA_DIRS=(
  "/service-data/hadoop/nn"
  "/service-data/hadoop/dn1"
  "/service-data/hadoop/dn2"
  "/service-data/hadoop/config"
)

# Function to create directories and set permissions
create_data_dirs() {
  for dir in "${HADOOP_DATA_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
      echo "[INFO] Creating directory $dir"
      mkdir -p "$dir"
      chmod -R 777 "$dir"  # Setting full permissions for simplicity, adjust as needed
    else
      echo "[INFO] Directory $dir already exists"
    fi
  done
}

# Function to start HDFS services
start_hdfs() {
  # Start NameNode
  restart_service "hadoop-namenode" "$SCRIPT_DIR/../docker-compose/docker-compose-hdfs.yml" "hadoop-namenode"

  # Start DataNode 1
  restart_service "hadoop-datanode-1" "$SCRIPT_DIR/../docker-compose/docker-compose-hdfs.yml" "hadoop-datanode-1"

  # Start DataNode 2
  restart_service "hadoop-datanode-2" "$SCRIPT_DIR/../docker-compose/docker-compose-hdfs.yml" "hadoop-datanode-2"
}

# Create the necessary directories with appropriate permissions
#create_data_dirs

# Start HDFS services
start_hdfs