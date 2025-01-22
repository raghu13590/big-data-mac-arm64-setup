FROM ubuntu:20.04 AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
ENV HADOOP_VERSION=3.3.6 HIVE_VERSION=4.0.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget gnupg software-properties-common lsb-release python3 git maven \
    openjdk-11-jdk curl ca-certificates autoconf automake libtool \
    build-essential zlib1g-dev libssl-dev libreadline-dev libffi-dev \
    libxml2-dev libxslt1-dev locales libsnappy-dev libbz2-dev liblzo2-2 \
    liblzo2-dev libzstd-dev libunwind-dev libkrb5-dev libpam0g-dev gcc g++ \
    make pkg-config libtirpc-dev libsasl2-dev libgsasl7-dev protobuf-compiler \
    libprotobuf-dev pmdk-tools libpmem-dev cmake nasm netcat net-tools less nano && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' PYTHONIOENCODING=utf-8
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 MAVEN_OPTS="-Xms512m -Xmx8192m"

# Build ISA-L, Hadoop, and Hive
RUN git clone https://github.com/intel/isa-l.git /isa-l-src && \
    cd /isa-l-src && ./autogen.sh && ./configure --prefix=/usr && make -j$(nproc) && make install && \
    cd / && rm -rf /isa-l-src && \
    git clone --branch rel/release-$HADOOP_VERSION --depth 1 https://github.com/apache/hadoop.git /hadoop-src && \
    cd /hadoop-src && \
    mvn clean package -Pdist,native -DskipTests -Dtar -Dmaven.javadoc.skip=true \
        -Dcmake.args="-DNO_PROTOC=1 -DNO_FUSE=1 -DNO_LIBWEBHDFS=1 -DNO_SASL=1" \
        -Drequire.openssl=true -Drequire.snappy=true -Drequire.zstd=true \
        -Drequire.lz4=true -Drequire.bzip2=true -Drequire.isal=true -Drequire.pmdk=true \
        -pl '!hadoop-hdfs-project/hadoop-hdfs-native-client' \
        -pl '!hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-applications-catalog/hadoop-yarn-applications-catalog-webapp' && \
    mkdir -p /opt/hadoop-$HADOOP_VERSION && \
    cp -r /hadoop-src/hadoop-dist/target/hadoop-$HADOOP_VERSION/* /opt/hadoop-$HADOOP_VERSION && \
    rm -rf /hadoop-src && \
    wget https://downloads.apache.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
    tar -xzf apache-hive-$HIVE_VERSION-bin.tar.gz && \
    mv apache-hive-$HIVE_VERSION-bin /opt/hive-$HIVE_VERSION && \
    rm -f apache-hive-$HIVE_VERSION-bin.tar.gz && \
    wget https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -O /opt/hive-$HIVE_VERSION/lib/postgresql-jdbc.jar

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
ENV HADOOP_VERSION=3.3.6 HIVE_VERSION=4.0.1
ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION HIVE_HOME=/opt/hive-$HIVE_VERSION
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8' PYTHONIOENCODING=utf-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jre-headless python3 curl netcat net-tools less nano && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -ms /bin/bash hadoop && \
    useradd -ms /bin/bash hive && \
    groupadd supergroup && \
    usermod -aG supergroup hadoop && \
    usermod -aG supergroup hive

COPY --from=builder /opt /opt
RUN mkdir -p $HADOOP_HOME/logs && chown -R hadoop:hadoop $HADOOP_HOME/logs

USER hadoop
WORKDIR /home/hadoop

COPY --chown=hadoop:hadoop entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]