# Set Spark-specific environment variables
export SPARK_MASTER_HOST='spark-master'
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
export HADOOP_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
export YARN_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop
export HADOOP_HOME=/opt/hadoop-3.3.6
export SPARK_DIST_CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath)