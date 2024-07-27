#!/bin/bash

# Source common functions
source ./scripts/common-functions.sh

# Restart Zookeeper if it's not running
./scripts/run-zookeeper.sh

# Verify if Zookeeper is running
verify_service "zookeeper"

# Restart Pinot services individually if they are not running
restart_service "pinot-controller" "docker-compose/docker-compose-pinot.yml" "pinot-controller"
restart_service "pinot-broker" "docker-compose/docker-compose-pinot.yml" "pinot-broker"
restart_service "pinot-server" "docker-compose/docker-compose-pinot.yml" "pinot-server"