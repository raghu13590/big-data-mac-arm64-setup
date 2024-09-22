#!/bin/bash

# Set up environment variables
export HADOOP_HOME=/opt/hadoop-3.3.6
export HADOOP_MAPRED_HOME=/opt/hadoop-3.3.6
export HIVE_HOME=/opt/hive-3.1.3
export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:$HIVE_HOME/lib/*
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_MAPRED_HOME/bin:$HADOOP_MAPRED_HOME/sbin:$HIVE_HOME/bin

# Function to initialize Hive schema
initialize_hive_schema() {
    $HIVE_HOME/bin/schematool -dbType postgres -initSchema
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
  hiveserver2)
    $HIVE_HOME/bin/hiveserver2
    ;;
  metastore)
    initialize_hive_schema
    $HIVE_HOME/bin/hive --service metastore
    ;;
  *)
    exec "$@"
    ;;
esac