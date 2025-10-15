# Licensed to the Apache Software Foundation (ASF) under one or more contributor license agreements.

FROM ubuntu:focal AS builder

# Use bash shell for all RUN commands with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set non-interactive frontend and preconfigure tzdata for non-interactive install
ARG TZ
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=${TZ}

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
ARG LANG
ARG LANGUAGE
ARG LC_ALL
ENV LANG=${LANG} LANGUAGE=${LANGUAGE} LC_ALL=${LC_ALL}
ARG PYTHONIOENCODING
ENV PYTHONIOENCODING=${PYTHONIOENCODING}

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
ARG MAVEN_HOME
ARG JAVA_HOME
ARG MAVEN_OPTS
ARG HADOOP_VERSION
ARG HIVE_VERSION
ARG POSTGRES_JDBC_VERSION
ARG HADOOP_USER
ARG HIVE_USER
ARG SUPERGROUP
ENV MAVEN_HOME=${MAVEN_HOME}
ENV JAVA_HOME=${JAVA_HOME}
ENV MAVEN_OPTS=${MAVEN_OPTS}
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HIVE_VERSION=${HIVE_VERSION}

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
    wget https://jdbc.postgresql.org/download/postgresql-${POSTGRES_JDBC_VERSION}.jar -O /opt/hive-$HIVE_VERSION/lib/postgresql-jdbc.jar

# Set environment variables
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HIVE_HOME=/opt/hive-$HIVE_VERSION
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:/usr/bin

# Create non-root users and configure permissions
RUN useradd -ms /bin/bash ${HADOOP_USER} && \
    useradd -ms /bin/bash ${HIVE_USER} && \
    mkdir -p $HADOOP_HOME/logs && \
    chown -R ${HADOOP_USER}:${HADOOP_USER} $HADOOP_HOME/logs && \
    groupadd ${SUPERGROUP} && \
    usermod -aG ${SUPERGROUP} ${HADOOP_USER} && \
    usermod -aG ${SUPERGROUP} ${HIVE_USER}

# Copy the entrypoint script and ensure correct permissions
COPY --chown=${HADOOP_USER}:${HADOOP_USER} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to 'hadoop' user
USER ${HADOOP_USER}
WORKDIR /home/${HADOOP_USER}

# Set the entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]