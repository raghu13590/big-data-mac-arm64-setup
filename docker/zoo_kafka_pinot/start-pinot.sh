#!/bin/bash

# Remove existing network if it exists
docker network rm pinot-demo || true

# Create network
docker network create pinot-demo

# Build and start Zookeeper, Kafka, and Pinot controller to set up the cluster
docker-compose up -d zookeeper kafka pinot-controller

# Wait for Zookeeper, Kafka, and Pinot controller to start
echo "Waiting for Zookeeper, Kafka, and Pinot controller to start..."
sleep 60

# Start the rest of the Pinot services
docker-compose up -d --build pinot-broker pinot-server pinot-minion

# Wait for Pinot services to start
echo "Waiting for Pinot services to start..."
sleep 60

# Verify services
docker-compose ps

echo "Pinot cluster is initialized and running."