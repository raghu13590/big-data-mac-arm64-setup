#!/bin/bash

# Set up environment variables
export HADOOP_HOME=/opt/hadoop-3.3.6
export HADOOP_MAPRED_HOME=/opt/hadoop-3.3.6
export HIVE_HOME=/opt/hive-4.0.0
export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:$HIVE_HOME/lib/*
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_MAPRED_HOME/bin:$HADOOP_MAPRED_HOME/sbin:$HIVE_HOME/bin

# Add hive and hadoop users to supergroup for full HDFS permissions
add_users_to_supergroup() {
    groupadd supergroup
    usermod -aG supergroup hadoop
    usermod -aG supergroup hive
}

# Function to initialize HDFS directories and set permissions
initialize_hdfs_directories() {
    # Wait for HDFS to be ready (Namenode and Datanode must be started)
    until hdfs dfs -ls /; do
        echo "Waiting for HDFS to start..."
        sleep 5
    done

    # Create warehouse directory if it does not exist
    if ! hdfs dfs -test -d /user/hive/warehouse; then
        echo "Creating /user/hive/warehouse directory in HDFS..."
        hdfs dfs -mkdir -p /user/hive/warehouse
        hdfs dfs -chmod -R 777 /user/hive/warehouse
        hdfs dfs -chown -R hive:hadoop /user/hive/warehouse

        hdfs dfs -mkdir -p /tmp/hadoop-yarn/staging
        hdfs dfs -chmod -R 777 /tmp
        hdfs dfs -chmod -R 777 /tmp/hadoop-yarn/staging
        hdfs dfs -chown -R hive:hadoop /tmp/hadoop-yarn/staging
    else
        echo "/user/hive/warehouse directory already exists"
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

# Add users to supergroup once at the beginning
add_users_to_supergroup

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
  hiveserver2)
    # Initialize HDFS directories before starting HiveServer2
    initialize_hdfs_directories
    $HIVE_HOME/bin/hiveserver2
    ;;
  metastore)
    initialize_hdfs_directories
    initialize_hive_schema
    $HIVE_HOME/bin/hive --service metastore
    ;;
  *)
    exec "$@"
    ;;
esac
