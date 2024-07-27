#!/bin/bash

# Function to check if a container is running
is_running() {
    docker inspect --format="{{.State.Running}}" "$1" 2>/dev/null | grep "true" > /dev/null
}

# Function to verify if a container started successfully and is healthy
verify_service() {
    local service_name="$1"
    local max_retries=10
    local retries=0

    if is_running "$service_name"; then
        echo "$service_name started successfully."
    else
        echo "Failed to start $service_name. Exiting."
        exit 1
    fi

    # Wait for the service to become healthy
    while [ $retries -lt $max_retries ]; do
        local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null)
        if [ "$health_status" == "healthy" ]; then
            echo "$service_name is healthy."
            return 0
        elif [ "$health_status" == "unhealthy" ]; then
            echo "$service_name is unhealthy. Checking logs..."
            docker logs "$service_name"
            exit 1
        elif [ -z "$health_status" ]; then
            echo "$service_name does not have a health check defined."
            return 0
        else
            echo "Unknown health status for $service_name: $health_status. Waiting..."
            sleep 30
        fi
        retries=$((retries+1))
    done

    echo "$service_name did not become healthy within the expected time. Checking logs..."
    docker logs "$service_name"
    exit 1
}

# Function to remove orphan containers
remove_orphan_containers() {
    local orphans=$(docker ps -aq -f status=exited)
    if [ ! -z "$orphans" ]; then
        echo "Removing orphan containers..."
        docker rm $orphans
    else
        echo "No orphan containers to remove."
    fi
}

# Function to restart a container if it's not running
restart_service() {
    local service_name="$1"
    local compose_file="$2"
    local service_container="$3"

    remove_orphan_containers

    if is_running "$service_container"; then
        echo "$service_name is already running."
    else
        echo "Starting $service_name..."
        docker-compose -f "$compose_file" up -d "$service_name"
        verify_service "$service_container"
    fi
}