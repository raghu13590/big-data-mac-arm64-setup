#!/bin/bash

# Assigning ownership of HDFS directories to the spark user
hdfs dfs -mkdir -p /user/spark
hdfs dfs -chown -R spark:spark /user/spark

# If the command is 'hdfs namenode', format if necessary
if [ "$1" = "hdfs" ] && [ "$2" = "namenode" ]; then
  # Check if the NameNode data directory is empty (not formatted)
  if [ ! -d /hadoop_data/hdfs/namenode/current ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force -nonInteractive
  fi
fi

# Execute the passed command
exec "$@"
