#!/bin/bash

# Source environment variables from .env if present
if [ -f "/opt/flink/.env" ]; then
    set -a
    source /opt/flink/.env
    set +a
fi

# Enable remote debugging if specified
if [ "$ENABLE_DEBUG" = "true" ]; then
    export JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:${DEBUG_PORT}"
fi

# Print environment variables for debugging
echo "JAVA_HOME: $JAVA_HOME"
echo "HADOOP_HOME: $HADOOP_HOME"
echo "HADOOP_CONF_DIR: $HADOOP_CONF_DIR"
echo "HADOOP_CLASSPATH: $HADOOP_CLASSPATH"
echo "FLINK_HOME: $FLINK_HOME"
echo "PATH: $PATH"
echo "JAVA_OPTS: $JAVA_OPTS"

# Update PATH to include Flink and Hadoop binaries
export PATH=$PATH:$HADOOP_HOME/bin:$FLINK_HOME/bin

# List Flink binaries and check paths
ls -l $FLINK_HOME/bin
which flink
which hadoop

# Source Flink environment variables if the file exists
if [ -f "$FLINK_HOME/conf/flink-env.sh" ]; then
  source "$FLINK_HOME/conf/flink-env.sh"
fi

# Copy Flink libraries to HDFS
hadoop fs -mkdir -p $FLINK_HDFS_LIB_PATH
hadoop fs -put $FLINK_HOME/lib/* $FLINK_HDFS_LIB_PATH/

# Add to entrypoint.sh before starting Flink
chown -R $HADOOP_USER_NAME:$HADOOP_USER_NAME $FLINK_HOME/log
chmod -R 755 $FLINK_HOME/log

# Execute the command passed to the container
exec "$@"