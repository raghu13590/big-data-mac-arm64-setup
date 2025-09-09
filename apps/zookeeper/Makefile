# Zookeeper Makefile delegating to Top-Level Makefile
.PHONY: up down build restart logs clean status health

ifneq (,$(wildcard .env))
    include .env
    export
endif

DOCKER_ARGS = COMPOSE_FILE=$(PROJECT_NAME)/$(COMPOSE_FILE) PROJECT_NAME=$(PROJECT_NAME)

up:
	$(MAKE) -C .. up HEALTHCHECK=false $(DOCKER_ARGS)
	@echo "Waiting for Zookeeper cluster to stabilize..."; \
	sleep 20
	$(MAKE) health VERBOSE=true
down:
	$(MAKE) -C .. down $(DOCKER_ARGS)

health:
	@services=$$(docker compose -f docker-compose.yml config --services); \
	for svc in $$services; do \
		if [ "$(VERBOSE)" = "true" ]; then \
			echo "performing health check for $$svc..."; \
			echo "Checking status of $$svc..."; \
		fi; \
		status_output=$$(docker exec $$svc zkServer.sh status 2>&1); \
		if [ "$(VERBOSE)" = "true" ]; then \
			echo "$$status_output"; \
		fi; \
		mode=$$(echo "$$status_output" | grep -oE 'Mode: (leader|follower|standalone)'); \
		if [ -n "$$mode" ]; then \
			if [ "$(VERBOSE)" = "true" ]; then echo "$$mode"; fi; \
		else \
			echo "Error: Could not determine mode for $$svc."; \
			exit 1; \
		fi; \
		if ! echo "$$status_output" | grep -E "Client port found|Mode"; then \
			echo "Error: $$svc is not healthy."; \
			exit 1; \
		fi; \
		if [ "$(VERBOSE)" = "true" ]; then \
			echo "Checking AdminServer for $$svc..."; \
		fi; \
		admin_port=$$(echo $$svc | grep -oE '[0-9]+'); \
		admin_url="http://localhost:808$$admin_port/commands"; \
		if curl -sSf "$$admin_url" > /dev/null; then \
			if [ "$(VERBOSE)" = "true" ]; then \
				echo "AdminServer for $$svc is accessible."; \
				echo "$$svc is running and healthy."; \
			fi; \
		else \
			echo "Error: AdminServer for $$svc is not accessible."; \
			exit 1; \
		fi; \
	done


