#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
export HADOOP_HOME=/opt/hadoop-3.3.6
export SPARK_HOME=/opt/spark
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin

# Enable remote debugging if specified
if [ "$ENABLE_DEBUG" = "true" ]; then
    export JAVA_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
fi

echo "JAVA_HOME: $JAVA_HOME"
echo "HADOOP_HOME: $HADOOP_HOME"
echo "SPARK_HOME: $SPARK_HOME"
echo "PATH: $PATH"
echo "JAVA_OPTS: $JAVA_OPTS"

ls -l $SPARK_HOME/bin
which spark-class

# Source Spark environment variables
if [ -f "$SPARK_HOME/conf/spark-env.sh" ]; then
  source "$SPARK_HOME/conf/spark-env.sh"
fi

# Execute the command passed to the container
exec "$@"