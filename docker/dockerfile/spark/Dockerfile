# Dockerfile for Spark Cluster

# Use Ubuntu focal as the base image
FROM ubuntu:focal

# Set the Spark version as an argument
ARG SPARK_VERSION=3.4.3

# Prevent apt-get from prompting for timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenJDK and other dependencies
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget curl python3 python3-pip tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install Spark
RUN wget https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for Spark UI
EXPOSE 8082 8083 8084 7077 18080

# Set the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Reset DEBIAN_FRONTEND to avoid affecting other tools
RUN unset DEBIAN_FRONTEND
