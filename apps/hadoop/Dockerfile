# Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements.

FROM ubuntu:focal AS builder

# Use bash shell for all RUN commands with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend and preconfigure tzdata for non-interactive install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Disable suggests/recommends to reduce image size and ensure non-interactive installation
RUN echo 'APT::Install-Recommends "0";' > /etc/apt/apt.conf.d/10disableextras && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/10disableextras && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget gnupg software-properties-common lsb-release python3 git maven \
        openjdk-11-jdk curl ca-certificates autoconf automake libtool \
        build-essential zlib1g-dev libssl-dev libreadline-dev libffi-dev \
        libxml2-dev libxslt1-dev locales libsnappy-dev libbz2-dev liblzo2-2 \
        liblzo2-dev libzstd-dev libunwind-dev libkrb5-dev libpam0g-dev gcc g++ \
        make pkg-config libtirpc-dev libsasl2-dev libgsasl7-dev protobuf-compiler \
        libprotobuf-dev pmdk-tools libpmem-dev cmake nasm netcat net-tools less nano \
        postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

# Install ISA-L from source and clean up after building to reduce image size
RUN git clone https://github.com/intel/isa-l.git /isa-l-src && \
    cd /isa-l-src && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /isa-l-src

# Set environment variables required to build Hadoop
ENV MAVEN_HOME=/usr/share/maven
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV MAVEN_OPTS="-Xms512m -Xmx8192m"
ENV HADOOP_VERSION=3.3.6
ENV HIVE_VERSION=4.0.1

# Build Hadoop from source and clean up unnecessary files
RUN git clone --branch rel/release-$HADOOP_VERSION --depth 1 https://github.com/apache/hadoop.git /hadoop-src && \
    cd /hadoop-src && \
    mvn clean package -Pdist,native -DskipTests -Dtar -Dmaven.javadoc.skip=true \
        -Dcmake.args="-DNO_PROTOC=1 -DNO_FUSE=1 -DNO_LIBWEBHDFS=1 -DNO_SASL=1" \
        -Drequire.openssl=true -Drequire.snappy=true -Drequire.zstd=true \
        -Drequire.lz4=true -Drequire.bzip2=true -Drequire.isal=true -Drequire.pmdk=true \
        -pl '!hadoop-hdfs-project/hadoop-hdfs-native-client' \
        -pl '!hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-applications-catalog/hadoop-yarn-applications-catalog-webapp' && \
    mkdir -p /opt/hadoop-$HADOOP_VERSION && \
    cp -r /hadoop-src/hadoop-dist/target/hadoop-$HADOOP_VERSION/* /opt/hadoop-$HADOOP_VERSION && \
    rm -rf /hadoop-src

# Install Hive and PostgreSQL JDBC Driver
RUN wget https://downloads.apache.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
    tar -xzf apache-hive-$HIVE_VERSION-bin.tar.gz && \
    mv apache-hive-$HIVE_VERSION-bin /opt/hive-$HIVE_VERSION && \
    rm -f apache-hive-$HIVE_VERSION-bin.tar.gz && \
    wget https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -O /opt/hive-$HIVE_VERSION/lib/postgresql-jdbc.jar

# Set environment variables
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HIVE_HOME=/opt/hive-$HIVE_VERSION
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:/usr/bin

# Create non-root users and configure permissions
RUN useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash hive && \
    mkdir -p $HADOOP_HOME/logs && \
    chown -R hadoop:hadoop $HADOOP_HOME/logs && \
    groupadd supergroup && \
    usermod -aG supergroup hadoop && \
    usermod -aG supergroup hive

# Copy the entrypoint script and ensure correct permissions
COPY --chown=hadoop:hadoop entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to 'hadoop' user
USER hadoop
WORKDIR /home/hadoop

# Set the entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]