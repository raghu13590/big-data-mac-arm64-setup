#!/bin/bash

# Function to generate Hadoop configuration files
generate_config() {
  CONFIG_DIR="$HADOOP_HOME/etc/hadoop"

  for conf in core-site hdfs-site yarn-site mapred-site; do
    : > "$CONFIG_DIR/${conf}.xml"
    echo '<?xml version="1.0" encoding="UTF-8"?>' >> "$CONFIG_DIR/${conf}.xml"
    echo '<configuration>' >> "$CONFIG_DIR/${conf}.xml"

    # Extract the prefix from conf name, e.g., 'core' from 'core-site'
    conf_prefix=$(echo "${conf%%-*}" | tr '[:lower:]' '[:upper:]')

    # Process environment variables matching the prefix
    env | grep "^${conf_prefix}_CONF_" | while IFS='=' read -r name value; do
      prop_name=$(echo "$name" | sed -e "s/^${conf_prefix}_CONF_//" | tr '_' '.')
      echo "  <property><name>${prop_name}</name><value>${value}</value></property>" >> "$CONFIG_DIR/${conf}.xml"
    done

    echo '</configuration>' >> "$CONFIG_DIR/${conf}.xml"
  done
}

# Generate configurations
generate_config

# If the command is 'hdfs namenode', format if necessary
if [ "$1" = "hdfs" ] && [ "$2" = "namenode" ]; then
  # Check if the NameNode data directory is empty (not formatted)
  if [ ! -d /hadoop_data/hdfs/namenode/current ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force -nonInteractive
  fi
fi

# Execute the passed command
exec "$@"
