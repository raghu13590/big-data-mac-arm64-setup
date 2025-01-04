# Dockerfile for Flink Cluster

# Use Ubuntu focal as the base image
FROM ubuntu:focal

# Set the Flink version as an argument
ARG FLINK_VERSION=1.14.0
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

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV FLINK_HOME=/opt/flink
ENV PATH=$PATH:$JAVA_HOME/bin:$FLINK_HOME/bin

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for Flink UI and JobManager RPC
EXPOSE 8081 6123 6124

# Set the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Reset DEBIAN_FRONTEND to avoid affecting other tools
RUN unset DEBIAN_FRONTEND