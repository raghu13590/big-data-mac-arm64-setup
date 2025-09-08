#!/bin/bash
set -e

# Function to wait for a service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3

    echo "Waiting for $service_name at $host:$port..."
    while ! nc -z "$host" "$port"; do
        echo "Waiting for $service_name to be ready..."
        sleep 2
    done
    echo "$service_name is ready!"
}

# Function to wait for Zookeeper ensemble
wait_for_zookeeper_ensemble() {
    echo "Waiting for Zookeeper ensemble to be ready..."
    local zk_addresses="${ZK_ADDRESS}"

    # Parse comma-separated addresses
    IFS=',' read -ra ZK_ARRAY <<< "$zk_addresses"

    for zk in "${ZK_ARRAY[@]}"; do
        IFS=':' read -ra ADDR <<< "$zk"
        wait_for_service "${ADDR[0]}" "${ADDR[1]}" "Zookeeper at ${zk}"
    done

    echo "Zookeeper ensemble is ready!"
}

# Function to start Pinot Controller
start_controller() {
    echo "Starting Pinot Controller..."

    # Wait for Zookeeper ensemble
    wait_for_zookeeper_ensemble

    # Start Controller
    cd $PINOT_HOME
    bin/pinot-admin.sh StartController \
        -clusterName ${PINOT_CLUSTER_NAME} \
        -zkAddress "${ZK_ADDRESS}"
}

# Function to start Pinot Broker
start_broker() {
    echo "Starting Pinot Broker..."

    # Wait for Zookeeper ensemble
    wait_for_zookeeper_ensemble

    # Give controller time to initialize cluster
    echo "Waiting for Controller to initialize cluster..."
    sleep 10

    # Start Broker
    cd $PINOT_HOME
    bin/pinot-admin.sh StartBroker \
        -clusterName ${PINOT_CLUSTER_NAME} \
        -zkAddress "${ZK_ADDRESS}"
}

# Function to start Pinot Server
start_server() {
    echo "Starting Pinot Server..."

    # Wait for Zookeeper ensemble
    wait_for_zookeeper_ensemble

    # Give broker and controller time to initialize
    echo "Waiting for Controller and Broker to be ready..."
    sleep 15

    # Start Server
    cd $PINOT_HOME
    bin/pinot-admin.sh StartServer \
        -clusterName ${PINOT_CLUSTER_NAME} \
        -zkAddress "${ZK_ADDRESS}"
}

# Function to start Pinot Minion
start_minion() {
    echo "Starting Pinot Minion..."

    # Wait for Zookeeper ensemble
    wait_for_zookeeper_ensemble

    # Give all other components time to initialize
    echo "Waiting for cluster components to be ready..."
    sleep 20

    # Start Minion
    cd $PINOT_HOME
    bin/pinot-admin.sh StartMinion \
        -clusterName ${PINOT_CLUSTER_NAME} \
        -zkAddress "${ZK_ADDRESS}"
}

# Main execution logic
case "${PINOT_COMPONENT}" in
    controller)
        start_controller
        ;;
    broker)
        start_broker
        ;;
    server)
        start_server
        ;;
    minion)
        start_minion
        ;;
    *)
        echo "Unknown component: ${PINOT_COMPONENT}"
        echo "Valid options: controller, broker, server, minion"
        exit 1
        ;;
esac