# Dockerfile for Flink Cluster

# Use Ubuntu focal as the base image
FROM ubuntu:focal

# Load environment variables from .env
COPY .env /opt/flink/.env

# Set the Flink version as an argument
ARG FLINK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION
ARG JAVA_VERSION

ENV JAVA_HOME=${JAVA_HOME}
ENV FLINK_HOME=${FLINK_HOME}
ENV HADOOP_HOME=${HADOOP_HOME}
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
ENV YARN_CONF_DIR=${YARN_CONF_DIR}
ENV HADOOP_USER_NAME=${HADOOP_USER_NAME}
ENV PATH=${PATH}

# Prevent apt-get from prompting for timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenJDK and other dependencies
RUN apt-get update && \
    apt-get install -y openjdk-${JAVA_VERSION}-jdk wget curl python3 python3-pip tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Flink
RUN wget https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz && \
    tar -xzf flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz -C /opt && \
    mv /opt/flink-${FLINK_VERSION} /opt/flink && \
    rm flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION}.tgz

# Install Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Add Flink Hadoop integration
RUN wget https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar -O /opt/flink/lib/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar

# Copy Hadoop configuration files
COPY --from=hadoop:3.3.6 /opt/hadoop-3.3.6/etc/hadoop /opt/hadoop-3.3.6/etc/hadoop

# Create hadoop user and set up permissions
RUN groupadd ${HADOOP_USER_NAME} && \
    useradd -m -s /bin/bash -g ${HADOOP_USER_NAME} ${HADOOP_USER_NAME} && \
    usermod -aG sudo ${HADOOP_USER_NAME} && \
    echo "${HADOOP_USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /tmp/flink-yarn-tmp && \
    mkdir -p ${HADOOP_HOME}/logs && \
    mkdir -p ${FLINK_HOME}/conf && \
    mkdir -p ${FLINK_HOME}/log && \
    mkdir -p /tmp/flink && \
    chmod -R 777 /tmp/flink-yarn-tmp && \
    chmod -R 777 ${HADOOP_HOME}/logs && \
    chmod -R 777 ${FLINK_HOME}/conf && \
    chmod -R 777 ${FLINK_HOME}/log && \
    chmod -R 777 /tmp/flink && \
    chown -R ${HADOOP_USER_NAME}:${HADOOP_USER_NAME} ${FLINK_HOME} && \
    chown -R ${HADOOP_USER_NAME}:${HADOOP_USER_NAME} ${HADOOP_HOME} && \
    chown -R ${HADOOP_USER_NAME}:${HADOOP_USER_NAME} /tmp/flink

# Expose ports for Flink UI and JobManager RPC
EXPOSE 8081 6123 6124

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]