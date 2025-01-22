#!/bin/bash

# Function to initialize HDFS directories and set permissions
initialize_hdfs_directories() {
    # Wait for HDFS to be ready (Namenode and Datanode must be started)
    until hdfs dfs -ls /; do
        echo "Waiting for HDFS to start..."
        sleep 5
    done

   # Create /user/hive/warehouse directory if it does not exist
       if ! hdfs dfs -test -d /user/hive/warehouse; then
           echo "Creating /user/hive/warehouse directory in HDFS..."
           hdfs dfs -mkdir -p /user/hive/warehouse
           hdfs dfs -chmod -R 777 /user/hive/warehouse
           hdfs dfs -chown -R hive:hadoop /user/hive/warehouse
       else
           echo "/user/hive/warehouse directory already exists"
       fi

   # Create /tmp/hadoop-yarn/staging directory if it does not exist
       if ! hdfs dfs -test -d /tmp/hadoop-yarn/staging; then
           echo "Creating /tmp/hadoop-yarn/staging directory in HDFS..."
           hdfs dfs -mkdir -p /tmp/hadoop-yarn/staging
           hdfs dfs -chmod -R 777 /tmp/hadoop-yarn/staging
           hdfs dfs -chown -R hive:hadoop /tmp/hadoop-yarn/staging
       else
           echo "/tmp/hadoop-yarn/staging directory already exists"
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