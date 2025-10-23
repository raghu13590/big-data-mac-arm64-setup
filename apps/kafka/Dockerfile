FROM ubuntu:focal

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
        wget openjdk-11-jdk curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set environment variables for Kafka
ENV KAFKA_VERSION=3.5.1
ENV KAFKA_HOME=/opt/kafka
ENV PATH=$PATH:$KAFKA_HOME/bin

# Download and install Kafka
RUN wget https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.12-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_2.12-${KAFKA_VERSION}.tgz -C /opt && \
    mv /opt/kafka_2.12-${KAFKA_VERSION} $KAFKA_HOME && \
    rm kafka_2.12-${KAFKA_VERSION}.tgz

# Copy the entrypoint script and ensure correct permissions
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose Kafka port
EXPOSE 9092

RUN echo "Listing files in $KAFKA_HOME/bin:" && ls -l "$KAFKA_HOME/bin"

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]