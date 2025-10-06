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
echo "Listing flink home directory:"
ls -l $FLINK_HOME
echo "Listing Flink bin directory:"
ls -l $FLINK_HOME/bin
echo "Checking flink and hadoop paths:"
which flink
which hadoop

# Source Flink environment variables if the file exists
if [ -f "$FLINK_HOME/conf/flink-env.sh" ]; then
  source "$FLINK_HOME/conf/flink-env.sh"
fi

# Copy Flink libraries to HDFS (only if Hadoop is accessible)
if hadoop fs -test -d / 2>/dev/null; then
    echo "Hadoop is accessible, copying Flink libraries to HDFS..."
    hadoop fs -mkdir -p $FLINK_HDFS_LIB_PATH 2>/dev/null || true
    hadoop fs -put $FLINK_HOME/lib/* $FLINK_HDFS_LIB_PATH/ 2>/dev/null || echo "Failed to copy libs to HDFS, continuing..."
else
    echo "Hadoop not accessible, skipping HDFS library copy..."
fi

# Add to entrypoint.sh before starting Flink
chown -R $HADOOP_USER_NAME:$HADOOP_USER_NAME $FLINK_HOME/log
chmod -R 755 $FLINK_HOME/log

# Execute the command passed to the container
exec "$@"