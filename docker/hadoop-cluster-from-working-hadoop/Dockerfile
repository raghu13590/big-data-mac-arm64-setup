# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information.

FROM ubuntu:focal

# Use bash shell for all RUN commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Disable recommends/suggests to reduce image size
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/10disableextras && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/10disableextras

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_TERSE=true

# Set working directory to /root for initial setup
WORKDIR /root

# Install required packages (OpenJDK, Maven, Git, and other build tools)
RUN apt-get -q update && \
    apt-get -q install -y --no-install-recommends \
        python3 \
        git \
        maven \
        openjdk-11-jdk \
        curl \
        gnupg \
        locales \
        build-essential \
        cmake \
        libssl-dev \
        libprotobuf-dev \
        protobuf-compiler \
        zlib1g-dev && \
    apt-get clean && \
    apt-get -q update --fix-missing && \
    rm -rf /var/lib/apt/lists/*

# Set locale (if needed)
RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

# Set environment variables required to build Hadoop
ENV MAVEN_HOME=/usr/share/maven
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV HADOOP_VERSION=3.3.6

# Set Hadoop directories and environment variables
ENV HADOOP_HOME=/hadoop-src/hadoop-dist/target/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Avoid out of memory errors in builds
ENV MAVEN_OPTS="-Xms256m -Xmx3072m"

# Skip GPG verification when downloading Yetus via yetus-wrapper
ENV HADOOP_SKIP_YETUS_VERIFICATION=true

# Install Node.js and Yarn for Hadoop UI components (Optional but useful for building Hadoop)
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Build Hadoop from source
RUN git clone https://github.com/apache/hadoop.git /hadoop-src && \
    cd /hadoop-src && \
    git checkout rel/release-$HADOOP_VERSION && \
    mvn package -Pdist,native -DskipTests -Dmaven.javadoc.skip=true -Dtar \
        -pl '!hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-applications-catalog/hadoop-yarn-applications-catalog-webapp'

# Create a non-root user 'hadoop' with a home directory
RUN useradd -ms /bin/bash hadoop

# Change ownership of Hadoop directories to 'hadoop' user
RUN chown -R hadoop:hadoop /hadoop-src

# Copy the 'hadoop_env_checks.sh' script to the 'hadoop' user's home directory and set permissions
COPY hadoop_env_checks.sh /home/hadoop/hadoop_env_checks.sh
RUN chown hadoop:hadoop /home/hadoop/hadoop_env_checks.sh && \
    chmod 755 /home/hadoop/hadoop_env_checks.sh

# Add the script execution to the 'hadoop' user's .bashrc
RUN echo '${HOME}/hadoop_env_checks.sh' >> /home/hadoop/.bashrc && \
    chown hadoop:hadoop /home/hadoop/.bashrc

# Switch to 'hadoop' user and set working directory
USER hadoop
WORKDIR /home/hadoop

# Set Hadoop environment variables for 'hadoop' user
ENV HADOOP_HOME=/hadoop-src/hadoop-dist/target/hadoop-$HADOOP_VERSION
ENV PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Set the default command to bash
CMD ["/bin/bash"]
