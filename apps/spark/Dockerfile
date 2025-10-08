# Dockerfile for Spark Cluster

# Use Ubuntu focal as the base image
FROM ubuntu:focal

# Set the Spark version as an argument
ARG SPARK_VERSION
ENV SPARK_VERSION=${SPARK_VERSION}
ARG HADOOP_VERSION
ENV HADOOP_VERSION=${HADOOP_VERSION}
ARG SPARK_HADOOP_VERSION
ENV SPARK_HADOOP_VERSION=${SPARK_HADOOP_VERSION}
ARG HADOOP_HOME
ENV HADOOP_HOME=${HADOOP_HOME}

# Prevent apt-get from prompting for timezone configuration
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenJDK, gcc, and other dependencies
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget curl python3 python3-pip tzdata build-essential gawk bison gettext texinfo && \
    rm -rf /var/lib/apt/lists/*

# Download and extract glibc source files
RUN wget https://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.gz && \
    tar -xzf glibc-2.36.tar.gz -C /opt && \
    rm glibc-2.36.tar.gz

# Compile the C source files
WORKDIR /opt/glibc-2.36
RUN mkdir build && cd build && ../configure --disable-sanity-checks && make

RUN echo "spark verison is ${SPARK_VERSION} and spark hadoop version is ${SPARK_HADOOP_VERSION}"

# Install Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION} /opt/spark && \
    rm spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz

# Install Hadoop binaries
RUN wget https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /opt \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV SPARK_HOME=/opt/spark
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for Spark UI
EXPOSE 8082 8083 8084 7077 18080

# Set the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Reset DEBIAN_FRONTEND to avoid affecting other tools
RUN unset DEBIAN_FRONTEND

RUN pip3 install pyspark