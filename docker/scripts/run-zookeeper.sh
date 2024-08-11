#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Create the zoo.cfg file
ZOOKEEPER_CONFIG_DIR="$SCRIPT_DIR/../service-data/zookeeper/configs"
ZOOKEEPER_CONFIG_FILE="$ZOOKEEPER_CONFIG_DIR/zoo.cfg"

mkdir -p "$ZOOKEEPER_CONFIG_DIR"

cat > "$ZOOKEEPER_CONFIG_FILE" <<EOL
tickTime=2000
dataDir=/data
clientPort=2181
initLimit=5
syncLimit=2

# Enable Admin Server
admin.enableServer=true
admin.serverPort=8080

# Whitelist four-letter word commands
4lw.commands.whitelist=srvr,ruok,stat,conf,envi
EOL

# Restart Zookeeper if it's not running
restart_service "zookeeper" "$SCRIPT_DIR/../docker-compose/docker-compose-zookeeper.yml" "zookeeper"