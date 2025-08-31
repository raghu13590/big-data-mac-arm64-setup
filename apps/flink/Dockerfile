# Dockerfile for Flink Cluster

# Use Ubuntu focal as the base image
FROM ubuntu:focal

# Set the Flink version as an argument
ARG FLINK_VERSION=1.17.0
ARG SCALA_VERSION=2.12

# Prevent apt-get from prompting for timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenJDK and other dependencies
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget curl python3 python3-pip tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Flink
RUN wget https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    tar -xzf flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz -C /opt && \
    mv /opt/flink-${FLINK_VERSION} /opt/flink && \
    rm flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz

# Install Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xzf hadoop-3.3.6.tar.gz -C /opt && \
    rm hadoop-3.3.6.tar.gz

# Add Flink Hadoop integration
RUN wget https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar -O /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar

# Copy Hadoop configuration files
COPY --from=hadoop:3.3.6 /opt/hadoop-3.3.6/etc/hadoop /opt/hadoop-3.3.6/etc/hadoop

# Create hadoop user and set up permissions
RUN groupadd hadoop && \
    useradd -m -s /bin/bash -g hadoop hadoop && \
    usermod -aG sudo hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /tmp/flink-yarn-tmp && \
    mkdir -p /opt/hadoop-3.3.6/logs && \
    mkdir -p /opt/flink/conf && \
    mkdir -p /opt/flink/log && \
    mkdir -p /tmp/flink && \
    chmod -R 777 /tmp/flink-yarn-tmp && \
    chmod -R 777 /opt/hadoop-3.3.6/logs && \
    chmod -R 777 /opt/flink/conf && \
    chmod -R 777 /opt/flink/log && \
    chmod -R 777 /tmp/flink && \
    chown -R hadoop:hadoop /opt/flink && \
    chown -R hadoop:hadoop /opt/hadoop-3.3.6 && \
    chown -R hadoop:hadoop /tmp/flink

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64 \
    FLINK_HOME=/opt/flink \
    HADOOP_HOME=/opt/hadoop-3.3.6 \
    HADOOP_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop \
    HADOOP_OPTS="-Djava.library.path=/opt/hadoop-3.3.6/lib/native" \
    HADOOP_CLASSPATH=/opt/hadoop-3.3.6/etc/hadoop:/opt/hadoop-3.3.6/share/hadoop/common/lib/*:/opt/hadoop-3.3.6/share/hadoop/common/*:/opt/hadoop-3.3.6/share/hadoop/hdfs:/opt/hadoop-3.3.6/share/hadoop/hdfs/lib/*:/opt/hadoop-3.3.6/share/hadoop/hdfs/*:/opt/hadoop-3.3.6/share/hadoop/mapreduce/lib/*:/opt/hadoop-3.3.6/share/hadoop/mapreduce/*:/opt/hadoop-3.3.6/share/hadoop/yarn:/opt/hadoop-3.3.6/share/hadoop/yarn/lib/*:/opt/hadoop-3.3.6/share/hadoop/yarn/* \
    HADOOP_USER_NAME=hadoop \
    YARN_CONF_DIR=/opt/hadoop-3.3.6/etc/hadoop \
    LD_LIBRARY_PATH=/opt/hadoop-3.3.6/lib/native \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/flink/bin:/opt/hadoop-3.3.6/bin

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for Flink UI and JobManager RPC
EXPOSE 8081 6123 6124

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]