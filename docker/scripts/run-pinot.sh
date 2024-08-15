#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common-functions.sh"

# Function to remove dead machines from Pinot
remove_dead_machines() {
    echo "$(timestamp) [INFO] Checking for dead machines in Pinot..."

    local pinot_controller_url="http://localhost:9000"
    local instances_endpoint="/instances"
    local retry_count=3
    local retry_delay=5

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        echo "$(timestamp) [ERROR] jq is not installed. Please install jq to parse JSON responses."
        return 1
    fi

    # Get all instances
    local instances=$(curl -s "${pinot_controller_url}${instances_endpoint}")

    # Parse the JSON response and check each instance
    echo "$instances" | jq -r '.instances[]' | while read -r instance; do
        local instance_endpoint="${instances_endpoint}/${instance}"
        local instance_info=$(curl -s "${pinot_controller_url}${instance_endpoint}")

        # Check for different statuses based on the instance type
        local is_alive=$(echo "$instance_info" | jq -r '.status')

        if [ "$is_alive" != "ALIVE" ]; then
            echo "$(timestamp) [INFO] Removing dead instance: $instance"

            for ((i=1; i<=retry_count; i++)); do
                local delete_response=$(curl -X DELETE -s "${pinot_controller_url}${instance_endpoint}")
                if [[ "$delete_response" == *"Successfully"* ]]; then
                    echo "$(timestamp) [INFO] Successfully removed instance: $instance"
                    break
                else
                    echo "$(timestamp) [WARNING] Failed to remove instance: $instance. Retrying in $retry_delay seconds... (Attempt $i/$retry_count)"
                    sleep $retry_delay
                fi

                if [ $i -eq $retry_count ]; then
                    echo "$(timestamp) [ERROR] Failed to remove instance: $instance after $retry_count attempts."
                fi
            done
        else
            echo "$(timestamp) [INFO] Instance $instance is alive."
        fi
    done

    echo "$(timestamp) [INFO] Finished removing dead machines."
}

# Restart Zookeeper if it's not running
"$SCRIPT_DIR/run-zookeeper.sh"

# Verify if Zookeeper is running
verify_service "zookeeper"

# Remove dead machines from Pinot
remove_dead_machines

# Restart Pinot services individually if they are not running
restart_service "pinot-controller" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-controller"
restart_service "pinot-broker" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-broker"
restart_service "pinot-server" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-server"
restart_service "pinot-minion" "$SCRIPT_DIR/../docker-compose/docker-compose-pinot.yml" "pinot-minion"