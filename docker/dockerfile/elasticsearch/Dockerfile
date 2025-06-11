# Dockerfile for Elasticsearch Cluster
FROM ubuntu:focal

# Set Elasticsearch version
ARG ES_VERSION=6.8.12

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget curl gnupg2 && \
    apt-get install -y openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install Elasticsearch
RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz && \
    tar -xzf elasticsearch-${ES_VERSION}.tar.gz -C /usr/share && \
    mv /usr/share/elasticsearch-${ES_VERSION} /usr/share/elasticsearch && \
    rm elasticsearch-${ES_VERSION}.tar.gz

# Add this after extracting elasticsearch
RUN mv /usr/share/elasticsearch/config /usr/share/elasticsearch/config-original && \
    mkdir /usr/share/elasticsearch/config

# Create elasticsearch user
RUN groupadd -g 1000 elasticsearch && \
    useradd -m -u 1000 -g 1000 -s /bin/bash elasticsearch && \
    chown -R elasticsearch:elasticsearch /usr/share/elasticsearch

# Set environment variables
ENV ES_HOME=/usr/share/elasticsearch \
    PATH=$PATH:/usr/share/elasticsearch/bin \
    ES_JAVA_OPTS="-Xms1g -Xmx1g -XX:+UseG1GC"

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports
EXPOSE 9200 9300

USER elasticsearch
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]