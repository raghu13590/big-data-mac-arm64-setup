# Keep only one LD_PRELOAD entry
LD_PRELOAD=/opt/bitnami/common/lib/libnss_wrapper.so

# Environment variables for Hadoop and YARN
export HADOOP_CONF_DIR=/opt/bitnami/hadoop/conf
export YARN_CONF_DIR=/opt/bitnami/hadoop/conf

# Set Spark to use YARN as the master
export SPARK_MASTER=yarnLD_PRELOAD=/opt/bitnami/common/lib/libnss_wrapper.so
