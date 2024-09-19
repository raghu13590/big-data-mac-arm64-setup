#!/bin/bash

# Set up environment variables
export HADOOP_HOME=/opt/hadoop-3.3.6
export HADOOP_MAPRED_HOME=/opt/hadoop-3.3.6
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_MAPRED_HOME/bin:$HADOOP_MAPRED_HOME/sbin

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
  *)
    exec "$@"
    ;;
esac