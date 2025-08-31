#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Function to clear previous machine states in Zookeeper
clear_zookeeper_state() {
    local zk_host="localhost:2181"
    local zk_container="zookeeper"  # Name of the Zookeeper container
    local paths=(
        "/PinotCluster/CONFIGS"
        "/PinotCluster/CONTROLLER"
        "/PinotCluster/EXTERNALVIEW"
        "/PinotCluster/IDEALSTATES"
        "/PinotCluster/INSTANCES"
        "/PinotCluster/LIVEINSTANCES"
        "/PinotCluster/PROPERTYSTORE"
        "/PinotCluster/STATEMODELDEFS"
    )

    for path in "${paths[@]}"; do
        echo "$(timestamp) [INFO] Removing Zookeeper path: $path"
        docker exec -it "$zk_container" /opt/bitnami/zookeeper/bin/zkCli.sh -server "$zk_host" deleteall "$path" || echo "$(timestamp) [WARN] Could not delete $path. It may not exist or is already cleaned up."
    done
}

# Restart Pinot services individually if they are not running
restart_service "pinot-controller" "$SCRIPT_DIR/../apps/pinot/docker-compose-pinot.yml" "pinot-controller"
sleep 10  # Add delay
restart_service "pinot-broker" "$SCRIPT_DIR/../apps/pinot/docker-compose-pinot.yml" "pinot-broker"
sleep 10  # Add delay
restart_service "pinot-server" "$SCRIPT_DIR/../apps/pinot/docker-compose-pinot.yml" "pinot-server"
sleep 10  # Add delay
restart_service "pinot-minion" "$SCRIPT_DIR/../apps/pinot/docker-compose-pinot.yml" "pinot-minion"