#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

COMPOSE_FILE="$SCRIPT_DIR/../docker-compose/docker-compose-elasticsearch.yml"
DOCKERFILE_DIR="$SCRIPT_DIR/../dockerfile/elasticsearch"

check_docker_running
validate_compose_file "$COMPOSE_FILE"

echo "Building Elasticsearch image..."
docker build -t elasticsearch-local "$DOCKERFILE_DIR"

# Start all nodes simultaneously using Docker Compose
docker-compose -f "$COMPOSE_FILE" up -d es01 es02 es03

# Wait for the Elasticsearch cluster to be operational
verify_service "es01"
verify_service "es02"
verify_service "es03"

restart_service "kibana" "$COMPOSE_FILE" "kibana"

echo "Elasticsearch cluster and Kibana are operational!"