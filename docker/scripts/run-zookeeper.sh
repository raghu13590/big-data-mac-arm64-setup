#!/bin/bash

# Source common functions
source ./scripts/common-functions.sh

# Restart Zookeeper if it's not running
restart_service "zookeeper" "docker-compose/docker-compose-zookeeper.yml" "zookeeper"