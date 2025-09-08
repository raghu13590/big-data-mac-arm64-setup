# Top-level Makefile for Docker Compose management
.PHONY: help build build-quick up up-minimal down restart logs clean status health

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "${GREEN}Top-Level Makefile for Docker Compose Management${NC}"
	@echo ""
	@echo "Usage:"
	@echo "  ${YELLOW}make${NC} ${GREEN}<target>${NC} [COMPOSE_FILE=<path>] [PROJECT_NAME=<name>]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##/) \
			printf "  ${YELLOW}%-20s${NC} %s\n", $$1, $$2 \
	}' $(MAKEFILE_LIST)

build: ## Build Docker images (no cache)
	@echo "${GREEN}Building Docker images for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) build --no-cache
	@echo "${GREEN}Build complete!${NC}"

build-quick: ## Quick build (uses cache)
	@echo "${GREEN}Building Docker images for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) build

up: ## Start all services
	@echo "${GREEN}Starting services for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d
	@if [ "$(HEALTHCHECK)" != "false" ]; then \
		echo "${GREEN}Waiting for services to be healthy...${NC}"; \
		sleep 30; \
		make health COMPOSE_FILE=$(COMPOSE_FILE) PROJECT_NAME=$(PROJECT_NAME); \
		echo "${GREEN}Services are up!${NC}"; \
	else \
		echo "${YELLOW}Skipping health check as requested.${NC}"; \
	fi

up-minimal: ## Start minimal services (example: Pinot only)
	@echo "${GREEN}Starting minimal services for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d pinot-controller pinot-broker pinot-server-1 pinot-server-2
	@echo "${GREEN}Minimal services are up!${NC}"

down: ## Stop all services
	@echo "${RED}Stopping services for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) down

restart: down up ## Restart all services

logs: ## View logs
	@echo "${GREEN}Viewing logs for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs -f

clean: ## Remove unused Docker resources
	@echo "${RED}Cleaning up unused Docker resources...${NC}"
	docker system prune -f

status: ## List running services
	@echo "${GREEN}Listing running services for $(PROJECT_NAME)...${NC}"
	docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps

health: ## Check health status of all components
	@echo "${GREEN}Checking health status of components for $(PROJECT_NAME)...${NC}"
	@for service in $$(docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps --services); do \
		status=$$(docker inspect --format='{{json .State.Health.Status}}' $$(docker-compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps -q $$service) 2>/dev/null); \
		if [ "$$status" != "\"healthy\"" ]; then \
			echo "Service $$service is not healthy (status: $$status). Check logs for details."; \
			exit 1; \
		fi; \
	done; \
	echo "All components are healthy!"
