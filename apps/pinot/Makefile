# Makefile for Apache Pinot Docker Setup with External Zookeeper
.PHONY: help build up down restart logs clean status health init-cluster create-table load-data scale

# Load environment variables from .env
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Variables
COMPOSE_FILE = docker-compose.yml
PROJECT_NAME = pinot-cluster
PINOT_VERSION = 1.2.0

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Show this help message
	@echo '${GREEN}Apache Pinot ${PINOT_VERSION} Docker Setup (with External Zookeeper)${NC}'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${NC} ${GREEN}<target>${NC}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##/) \
			printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)

build: ## Build Docker images for ARM64
	@echo "${GREEN}Building Pinot ${PINOT_VERSION} Docker images for ARM64...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) build --no-cache
	@echo "${GREEN}Build complete!${NC}"

build-quick: ## Quick build without cache clearing
	@echo "${GREEN}Building Pinot Docker images...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) build

up: ## Start all Pinot services
	@echo "${GREEN}Starting Pinot cluster...${NC}"
	@echo "${YELLOW}Note: Ensure Zookeeper ensemble is running first!${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d
	@echo "${GREEN}Waiting for services to be healthy...${NC}"
	@sleep 30
	@make health
	@echo "${GREEN}Pinot cluster is up!${NC}"
	@echo "Controller UI: ${YELLOW}http://localhost:9000${NC}"
	@echo "Broker endpoint: ${YELLOW}http://localhost:8099${NC}"
	@echo "Query Console: ${YELLOW}http://localhost:9000/#/query${NC}"

up-minimal: ## Start minimal Pinot services (no Kafka/MinIO)
	@echo "${GREEN}Starting minimal Pinot cluster...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d \
		pinot-controller pinot-broker pinot-server-1 pinot-server-2
	@echo "${GREEN}Minimal cluster is up!${NC}"

down: ## Stop all Pinot services
	@echo "${RED}Stopping Pinot cluster...${NC}"

health: ## Check health status of Pinot components
	@echo "Checking health status of Pinot components..."
	@for service in $$(docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps --services); do \
		status=$$(docker inspect --format='{{json .State.Health.Status}}' $$(docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps -q $$service) 2>/dev/null); \
		if [ "$$status" != "\"healthy\"" ]; then \
			echo "Service $$service is not healthy (status: $$status). Check logs for details."; \
			exit 1; \
		fi; \
	done; \
	echo "All components are healthy!"