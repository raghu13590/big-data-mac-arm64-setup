#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Function to remove dead machines from Zookeeper using Docker exec
remove_dead_machines_with_zookeeper() {
    echo "$(timestamp) [INFO] Fetching instances from /PinotCluster/INSTANCES..."

    # Fetch the instances from ZooKeeper
    instances_output=$(docker exec -i zookeeper /opt/bitnami/zookeeper/bin/zkCli.sh -server zookeeper:2181 ls /PinotCluster/INSTANCES 2>&1 | grep '^\[')
    #echo "$(timestamp) [INFO] Raw command output: $instances_output"

    # Extract instances
    instances=$(echo "$instances_output" | tr -d '[]' | tr -d ' ')
    echo "$(timestamp) [INFO] Extracted instances: $instances"

    if [ -z "$instances" ]; then
        echo "$(timestamp) [ERROR] No instances found under /PinotCluster/INSTANCES."
        return 1
    fi

    # Fetch the live instances from ZooKeeper
    echo "$(timestamp) [INFO] Fetching live instances from /PinotCluster/LIVEINSTANCES..."
    live_instances_output=$(docker exec -i zookeeper /opt/bitnami/zookeeper/bin/zkCli.sh -server zookeeper:2181 ls /PinotCluster/LIVEINSTANCES 2>&1 | grep '^\[')
    #echo "$(timestamp) [INFO] Raw command output: $live_instances_output"

    # Extract live instances
    live_instances=$(echo "$live_instances_output" | tr -d '[]' | tr -d ' ')
    echo "$(timestamp) [INFO] Extracted live instances: $live_instances"

    # Split the instances into arrays
    IFS=',' read -r -a instances_array <<< "$instances"
    IFS=',' read -r -a live_instances_array <<< "$live_instances"

    # Function to recursively delete a Zookeeper node
    delete_znode_recursive() {
        local node=$1
        children=$(docker exec -i zookeeper /opt/bitnami/zookeeper/bin/zkCli.sh -server zookeeper:2181 ls $node 2>&1 | grep '^\[' | tr -d '[]' | tr ',' '\n')

        for child in $children; do
            delete_znode_recursive "$node/$child"
        done

        docker exec -i zookeeper /opt/bitnami/zookeeper/bin/zkCli.sh -server zookeeper:2181 delete $node
        echo "$(timestamp) [INFO] Deleted node: $node"
    }

    # Loop through instances and remove those not in live_instances
    for instance in "${instances_array[@]}"; do
        echo "$(timestamp) [INFO] Parsed instance: '$instance'"

        found=false
        for live_instance in "${live_instances_array[@]}"; do
            if [ "$instance" == "$live_instance" ]; then
                found=true
                break
            fi
        done

        if [ "$found" == false ]; then
            echo "$(timestamp) [WARNING] Instance $instance is not live, removing..."
            delete_znode_recursive "/PinotCluster/INSTANCES/$instance"
            echo "$(timestamp) [INFO] Instance $instance removed."
        else
            echo "$(timestamp) [INFO] Instance $instance is alive."
        fi
    done
}

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Call the function to remove dead machines
#remove_dead_machines_with_zookeeper

#Restart Pinot services individually if they are not running
restart_service "pinot-controller" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-controller"
restart_service "pinot-broker" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-broker"
restart_service "pinot-server" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-server"
restart_service "pinot-minion" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-minion"

# Verify if Pinot services are healthy
verify_service "pinot-controller"
verify_service "pinot-broker"
verify_service "pinot-server"
verify_service "pinot-minion"