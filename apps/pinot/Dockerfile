# Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements.

FROM ubuntu:focal AS builder

# Use bash shell for all RUN commands with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend and preconfigure tzdata
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Disable suggests/recommends to reduce image size
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/10disableextras && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/10disableextras && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget curl gnupg software-properties-common lsb-release \
        openjdk-11-jdk ca-certificates git maven \
        build-essential netcat net-tools less nano vim \
        jq unzip procps dnsutils iputils-ping \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV PATH=$JAVA_HOME/bin:$PATH

# Set Pinot version and installation directory
ENV PINOT_VERSION=1.2.0
ENV PINOT_HOME=/opt/pinot

# Download and install Apache Pinot 1.2.0 (using binary for ARM64)
RUN mkdir -p ${PINOT_HOME} && \
    cd /tmp && \
    wget -q https://archive.apache.org/dist/pinot/apache-pinot-${PINOT_VERSION}/apache-pinot-${PINOT_VERSION}-bin.tar.gz && \
    tar -xzf apache-pinot-${PINOT_VERSION}-bin.tar.gz && \
    mv apache-pinot-${PINOT_VERSION}-bin/* ${PINOT_HOME}/ && \
    rm -rf /tmp/apache-pinot-*

# Download additional plugins and dependencies for 1.2.0
RUN cd ${PINOT_HOME}/plugins && \
    # Download Kafka connector if needed for streaming
    wget -q https://repo1.maven.org/maven2/org/apache/pinot/pinot-kafka-2.0/${PINOT_VERSION}/pinot-kafka-2.0-${PINOT_VERSION}-shaded.jar || true && \
    # Download S3 plugin for deep storage
    wget -q https://repo1.maven.org/maven2/org/apache/pinot/pinot-s3/${PINOT_VERSION}/pinot-s3-${PINOT_VERSION}-shaded.jar || true && \
    # Download Avro plugin
    wget -q https://repo1.maven.org/maven2/org/apache/pinot/pinot-avro/${PINOT_VERSION}/pinot-avro-${PINOT_VERSION}-shaded.jar || true

# Set environment variables
ENV PATH=$PATH:${PINOT_HOME}/bin

# Create necessary directories with proper permissions
RUN mkdir -p /var/pinot/controller/data \
             /var/pinot/controller/logs \
             /var/pinot/server/data \
             /var/pinot/server/logs \
             /var/pinot/broker/logs \
             /var/pinot/minion/data \
             /var/pinot/minion/logs \
             /opt/pinot/configs \
             /opt/pinot/scripts

# Create non-root user for running services
RUN useradd -ms /bin/bash pinot && \
    chown -R pinot:pinot /var/pinot ${PINOT_HOME}

# Make scripts executable
RUN chmod +x /opt/pinot/scripts/*.sh 2>/dev/null || true

# Copy entrypoint script
COPY --chown=pinot:pinot entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to pinot user
USER pinot
WORKDIR /home/pinot

# Set JVM options for ARM64 optimization
ENV JVM_OPTS="-Xms1G -Xmx4G -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication"

ENTRYPOINT ["/entrypoint.sh"]