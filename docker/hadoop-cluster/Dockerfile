# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.

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
        python3 \
        git \
        maven \
        openjdk-11-jdk \
        curl \
        gnupg \
        ca-certificates \
        autoconf \
        automake \
        libtool \
        build-essential \
        zlib1g-dev \
        libssl-dev \
        libreadline-dev \
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        protobuf-compiler \
        libprotobuf-dev \
        locales \
        libsnappy-dev \
        libbz2-dev \
        liblzo2-2 \
        liblzo2-dev \
        libzstd-dev \
        libunwind-dev \
        libkrb5-dev \
        libpam0g-dev \
        gcc \
        g++ \
        make \
        pkg-config \
        libtirpc-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

# Set environment variables required to build Hadoop
ENV MAVEN_HOME=/usr/share/maven
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64

# Avoid out of memory errors in builds
ENV MAVEN_OPTS="-Xms512m -Xmx4096m"

# Skip gpg verification when downloading Yetus via yetus-wrapper
ENV HADOOP_SKIP_YETUS_VERIFICATION=true

# Build Hadoop from source
ENV HADOOP_VERSION=3.3.6

RUN git clone https://github.com/apache/hadoop.git /hadoop-src && \
    cd /hadoop-src && \
    git checkout rel/release-$HADOOP_VERSION

# Exclude native components to avoid the need for CMake
RUN sed -i 's/<native>//g' /hadoop-src/pom.xml && \
    sed -i 's#</native>##g' /hadoop-src/pom.xml

# Build Hadoop without native components and extract the distribution
RUN cd /hadoop-src && \
    mvn package -Pdist -DskipTests -Dmaven.javadoc.skip=true -Dtar \
        -pl '!hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-applications-catalog/hadoop-yarn-applications-catalog-webapp' && \
    tar -xzf hadoop-dist/target/hadoop-$HADOOP_VERSION.tar.gz -C /opt/ && \
    rm -rf /hadoop-src

# Set HADOOP_HOME to the extracted directory
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV PATH="${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"

# Create a non-root user 'hadoop' with a home directory
RUN useradd -ms /bin/bash hadoop

# Change ownership of Hadoop directories to 'hadoop' user
RUN chown -R hadoop:hadoop $HADOOP_HOME

# Switch to 'hadoop' user
USER hadoop
WORKDIR /home/hadoop

# Copy the entrypoint script
COPY --chown=hadoop:hadoop entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Set default command
CMD ["/bin/bash"]
