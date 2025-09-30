#!/bin/bash

# Check that required environment variables are set
if [[ -z "$HDFS_WAREHOUSE_DIR" || -z "$HDFS_STAGING_DIR" || -z "$HDFS_OWNER" || -z "$HDFS_PERMISSIONS" ]]; then
    echo "Error: One or more required environment variables (HDFS_WAREHOUSE_DIR, HDFS_STAGING_DIR, HDFS_OWNER, HDFS_PERMISSIONS) are not set."
    exit 1
fi

# Function to initialize HDFS directories and set permissions
initialize_hdfs_directories() {
    # Wait for HDFS to be ready (Namenode and Datanode must be started)
    until hdfs dfs -ls /; do
        echo "Waiting for HDFS to start..."
        sleep 5
    done

    # Create warehouse directory if it does not exist
    if ! hdfs dfs -test -d "$HDFS_WAREHOUSE_DIR"; then
        echo "Creating $HDFS_WAREHOUSE_DIR directory in HDFS..."
        hdfs dfs -mkdir -p "$HDFS_WAREHOUSE_DIR"
        hdfs dfs -chmod -R "$HDFS_PERMISSIONS" "$HDFS_WAREHOUSE_DIR"
        hdfs dfs -chown -R "$HDFS_OWNER" "$HDFS_WAREHOUSE_DIR"
    else
        echo "$HDFS_WAREHOUSE_DIR directory already exists"
    fi

    # Create staging directory if it does not exist
    if ! hdfs dfs -test -d "$HDFS_STAGING_DIR"; then
        echo "Creating $HDFS_STAGING_DIR directory in HDFS..."
        hdfs dfs -mkdir -p "$HDFS_STAGING_DIR"
        hdfs dfs -chmod -R "$HDFS_PERMISSIONS" "$HDFS_STAGING_DIR"
        hdfs dfs -chown -R "$HDFS_OWNER" "$HDFS_STAGING_DIR"
    else
        echo "$HDFS_STAGING_DIR directory already exists"
    fi
}

# Function to initialize Hive schema
initialize_hive_schema() {
    if ! $HIVE_HOME/bin/schematool -dbType postgres -info; then
        echo "Initializing Hive schema..."
        $HIVE_HOME/bin/schematool -dbType postgres -initSchema
    else
        echo "Hive schema already initialized."
    fi
}

# Start the specified Hadoop component
case "$1" in
  namenode)
    hdfs namenode
    ;;
  datanode)
    hdfs datanode
    ;;
  resourcemanager)
    yarn --config $HADOOP_HOME/etc/hadoop resourcemanager
    ;;
  nodemanager)
    yarn --config $HADOOP_HOME/etc/hadoop nodemanager
    ;;
  metastore)
    initialize_hdfs_directories
    initialize_hive_schema
    $HIVE_HOME/bin/hive --service metastore
    ;;
  hiveserver2)
    initialize_hdfs_directories
    $HIVE_HOME/bin/hiveserver2
    ;;
  *)
    exec "$@"
    ;;
esac