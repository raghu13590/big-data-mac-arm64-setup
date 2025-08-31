#!/bin/bash

# Enable remote debugging if specified
if [ "$ENABLE_DEBUG" = "true" ]; then
    export JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
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
export HADOOP_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
export YARN_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
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
hadoop fs -mkdir -p /flink/lib
hadoop fs -put /opt/flink/lib/* /flink/lib/

# Add to entrypoint.sh before starting Flink
chown -R hadoop:hadoop /opt/flink/log
chmod -R 755 /opt/flink/log

# Execute the command passed to the container
exec "$@"