# Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements.

FROM ubuntu:focal

# Use bash shell for all RUN commands with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Disable suggests/recommends to reduce image size
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/10disableextras && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/10disableextras

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_TERSE=true

# Set working directory to /root for initial setup
WORKDIR /root

# Install required packages
RUN apt-get -q update && \
    apt-get -q install -y --no-install-recommends \
        wget \
        gnupg \
        software-properties-common \
        lsb-release \
        python3 \
        git \
        openjdk-11-jdk \
        curl \
        ca-certificates \
        locales \
        netcat \
        net-tools \
        less \
        nano && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

# Set environment variables required to run Spark
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64

# Install Spark
ENV SPARK_VERSION=3.4.3
RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    tar -xzf spark-$SPARK_VERSION-bin-hadoop3.tgz && \
    mv spark-$SPARK_VERSION-bin-hadoop3 /opt/spark-$SPARK_VERSION && \
    rm spark-$SPARK_VERSION-bin-hadoop3.tgz

ENV SPARK_HOME=/opt/spark-$SPARK_VERSION
ENV PATH=$SPARK_HOME/bin:$PATH

# Create a non-root user 'spark' with a home directory
RUN useradd -ms /bin/bash spark

# Add spark to supergroup for full HDFS permissions
RUN groupadd supergroup && \
    usermod -aG supergroup spark

# Switch to 'spark' user
USER spark
WORKDIR /home/spark

# Copy the entrypoint script
COPY --chown=spark:spark entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Set default command
CMD ["/bin/bash"]