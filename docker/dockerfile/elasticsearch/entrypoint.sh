#!/bin/bash
set -e

# Clean up any existing config symlinks
rm -rf /usr/share/elasticsearch/config/config

# Set proper permissions and copy config
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data
mkdir -p /usr/share/elasticsearch/config
cp /usr/share/elasticsearch/config-original/log4j2.properties /usr/share/elasticsearch/config/

# Start Elasticsearch with full configuration
exec /usr/share/elasticsearch/bin/elasticsearch