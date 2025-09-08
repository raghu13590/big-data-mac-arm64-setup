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
	@for i in 1 2 3; do \
  if [ "$(VERBOSE)" = "true" ]; then \
    echo performing health check for zookeeper$$i...; \
    echo "Checking status of zookeeper$$i..."; \
  fi; \
  status_output=$$(docker exec zookeeper$$i zkServer.sh status 2>&1); \
  if [ "$(VERBOSE)" = "true" ]; then \
    echo "$$status_output"; \
  fi; \
  mode=$$(echo "$$status_output" | grep -oE 'Mode: (leader|follower|standalone)'); \
  if [ -n "$$mode" ]; then \
    if [ "$(VERBOSE)" = "true" ]; then echo "$$mode"; fi; \
  else \
    echo "Error: Could not determine mode for zookeeper$$i."; \
    exit 1; \
  fi; \
  if ! echo "$$status_output" | grep -E "Client port found|Mode"; then \
    echo "Error: zookeeper$$i is not healthy."; \
    exit 1; \
  fi; \
  if [ "$(VERBOSE)" = "true" ]; then \
    echo "Checking AdminServer for zookeeper$$i..."; \
  fi; \
  admin_url="http://localhost:808$$i/commands"; \
  if curl -sSf "$$admin_url" > /dev/null; then \
    if [ "$(VERBOSE)" = "true" ]; then \
      echo "AdminServer for zookeeper$$i is accessible."; \
      echo "zookeeper$$i is running and healthy."; \
    fi; \
  else \
    echo "Error: AdminServer for zookeeper$$i is not accessible."; \
    exit 1; \
  fi; \
 done; \
 if [ "$(VERBOSE)" = "true" ]; then \
   echo ""; \
   echo "Zookeeper AdminServer URLs:"; \
   for i in 1 2 3; do \
     echo "Zookeeper$$i: http://localhost:808$$i/commands"; \
   done; \
   echo "Zookeeper cluster is running and healthy!"; \
 fi

