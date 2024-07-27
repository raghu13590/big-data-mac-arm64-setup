#!/bin/bash

# Source common functions
source ./scripts/common-functions.sh

# Start Zookeeper if not already running
./scripts/run-zookeeper.sh

# Verify if Zookeeper is running
verify_service "zookeeper"

# Remove orphaned containers
remove_orphans "docker-compose/docker-compose-pinot.yml"

# Restart Pinot services individually if they are not running
restart_service "pinot-controller" "docker-compose/docker-compose-pinot.yml" "pinot-controller"
verify_service "pinot-controller"

restart_service "pinot-broker" "docker-compose/docker-compose-pinot.yml" "pinot-broker"
verify_service "pinot-broker"

restart_service "pinot-server" "docker-compose/docker-compose-pinot.yml" "pinot-server"
verify_service "pinot-server"