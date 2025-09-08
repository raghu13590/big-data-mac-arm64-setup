# Pinot Makefile delegating to Top-Level Makefile
.PHONY: up down build restart logs clean status health

ifneq (,$(wildcard .env))
    include .env
    export
endif

DOCKER_ARGS = COMPOSE_FILE=$(PROJECT_NAME)/$(COMPOSE_FILE) PROJECT_NAME=$(PROJECT_NAME)

up:
	@echo "Checking Zookeeper health..."
	@if $(MAKE) -C ../zookeeper health; then echo "Zookeeper is healthy, proceeding to start Pinot"; \
	else \
		echo "Zookeeper not healthy, starting..."; \
		$(MAKE) -C ../zookeeper up; \
		$(MAKE) -C ../zookeeper health || (echo "Zookeeper failed to start"; exit 1); \
	fi
	@$(MAKE) -C .. up $(DOCKER_ARGS)
down:
	$(MAKE) -C .. down $(DOCKER_ARGS)
build:
	$(MAKE) -C .. build $(DOCKER_ARGS)
build-quick:
	$(MAKE) -C .. build $(DOCKER_ARGS)
restart:
	$(MAKE) -C .. restart $(DOCKER_ARGS)
logs:
	$(MAKE) -C .. logs $(DOCKER_ARGS)
clean:
	$(MAKE) -C .. clean $(DOCKER_ARGS)
status:
	$(MAKE) -C .. status $(DOCKER_ARGS)
health:
	$(MAKE) -C .. health $(DOCKER_ARGS)
