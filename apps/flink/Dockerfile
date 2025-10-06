# Dockerfile for Flink Cluster

# Use the official Flink image as base
FROM flink:1.17.0-scala_2.12

# Load environment variables from .env
COPY .env /opt/flink/.env

# Set environment variables
ARG FLINK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION
ARG JAVA_VERSION
ARG HADOOP_USER_NAME
ARG FLINK_HOME
ARG HADOOP_HOME
ARG FLINK_LIB_PATH

ENV JAVA_HOME=/opt/java/openjdk
ENV FLINK_HOME=${FLINK_HOME}
ENV HADOOP_HOME=${HADOOP_HOME}
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
ENV YARN_CONF_DIR=${HADOOP_CONF_DIR}
ENV HADOOP_USER_NAME=${HADOOP_USER_NAME}
ENV PATH=${PATH}:${HADOOP_HOME}/bin
ENV FLINK_LIB_PATH=${FLINK_LIB_PATH}

# Switch to root to install packages
USER root

# Install additional dependencies
RUN apt-get update && \
    apt-get install -y wget curl python3 python3-pip sudo && \
    rm -rf /var/lib/apt/lists/*

# Install Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# Add Flink Hadoop integration
RUN mkdir -p ${FLINK_LIB_PATH} && \
    wget https://repo1.maven.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar -O ${FLINK_LIB_PATH}/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar

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