# apps/hadoop/Makefile

include ../Makefile.common

.PHONY: build-hadoop format-namenode clean-hadoop reset-metastore init-metastore reset-hive-warehouse up up-reset test

HADOOP_DOCKERFILE_DIR := $(CURDIR)
APP_DATA_DIR := $(abspath $(CURDIR)/../../app-data/hadoop)
DOCKER_COMPOSE_HADOOP := docker-compose -f $(CURDIR)/docker-compose.yml -p $(PROJECT_NAME)
SERVICES := namenode datanode1 datanode2 resourcemanager nodemanager1 nodemanager2 postgres metastore hiveserver2

build-hadoop:
	@echo "$(GREEN)Building Hadoop image...$(NC)"
	docker build -t hadoop:3.3.6 $(HADOOP_DOCKERFILE_DIR)

format-namenode:
	@echo "$(GREEN)Formatting Hadoop NameNode...$(NC)"
	$(DOCKER_COMPOSE_HADOOP) run --rm namenode hdfs namenode -format -force

clean-hadoop:
	@echo "$(RED)Stopping all Hadoop containers and removing volumes...$(NC)"
	$(DOCKER_COMPOSE_HADOOP) down -v
	@for service in $(SERVICES); do \
		echo "$(RED)Clearing $$service data...$(NC)"; \
		if [ -d $(APP_DATA_DIR)/$$service ]; then \
			find $(APP_DATA_DIR)/$$service -mindepth 1 -delete; \
		fi \
	done

init-metastore:
	@echo "$(GREEN)Initializing Hive metastore schema if needed...$(NC)"
	@if [ "$$($(DOCKER_COMPOSE_HADOOP) exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then \
		$(DOCKER_COMPOSE_HADOOP) exec metastore sh -c '$$HIVE_HOME/bin/schematool -dbType postgres -initSchema'; \
	else \
		echo "Metastore schema already exists. Skipping initialization."; \
	fi

reset-metastore:
	@echo "$(GREEN)Resetting Hive metastore database...$(NC)"
	@if $(DOCKER_COMPOSE_HADOOP) exec postgres psql -U hive -d postgres -lqt | cut -d \| -f 1 | grep -qw metastore; then \
		$(DOCKER_COMPOSE_HADOOP) exec postgres psql -U hive -d postgres -c "DROP DATABASE metastore;"; \
	fi
	$(DOCKER_COMPOSE_HADOOP) exec postgres psql -U hive -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'metastore';" | grep -q 1 || \
		$(DOCKER_COMPOSE_HADOOP) exec postgres psql -U hive -d postgres -c "CREATE DATABASE metastore;"
	@if [ "$$($(DOCKER_COMPOSE_HADOOP) exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then \
		$(DOCKER_COMPOSE_HADOOP) exec metastore sh -c '$$HIVE_HOME/bin/schematool -dbType postgres -initSchema'; \
	else \
		echo "Metastore schema already exists. Skipping initialization."; \
	fi

test:
	@$(CURDIR)/../../scripts/tests/test-hadoop.sh

up: ## Start Hadoop services (normal flow, no reset)
	@$(MAKE) dependencies
	@$(MAKE) up-service SERVICE=namenode
	@$(MAKE) health-service-retry SERVICE=namenode
	@$(MAKE) up-service SERVICE=datanode1
	@$(MAKE) health-service-retry SERVICE=datanode1
	@$(MAKE) up-service SERVICE=datanode2
	@$(MAKE) health-service-retry SERVICE=datanode2
	@$(MAKE) up-service SERVICE=resourcemanager
	@$(MAKE) health-service-retry SERVICE=resourcemanager
	@$(MAKE) up-service SERVICE=nodemanager1
	@$(MAKE) health-service-retry SERVICE=nodemanager1
	@$(MAKE) up-service SERVICE=nodemanager2
	@$(MAKE) health-service-retry SERVICE=nodemanager2
	@$(MAKE) up-service SERVICE=postgres
	@$(MAKE) health-service-retry SERVICE=postgres
	@$(MAKE) up-service SERVICE=metastore
	@$(MAKE) health-service-retry SERVICE=metastore
	@$(MAKE) init-metastore
	@$(MAKE) up-service SERVICE=hiveserver2
	@$(MAKE) health-service-retry SERVICE=hiveserver2
	@$(MAKE) test

up-reset: ## Perform a full clean install and start Hadoop services
	@$(MAKE) dependencies
	@$(MAKE) build-hadoop
	@$(MAKE) clean-hadoop
	@$(MAKE) format-namenode
	@$(MAKE) up-service SERVICE=namenode
	@$(MAKE) health-service-retry SERVICE=namenode
	@$(MAKE) reset-hive-warehouse
	@$(MAKE) up-service SERVICE=datanode1
	@$(MAKE) health-service-retry SERVICE=datanode1
	@$(MAKE) up-service SERVICE=datanode2
	@$(MAKE) health-service-retry SERVICE=datanode2
	@$(MAKE) up-service SERVICE=resourcemanager
	@$(MAKE) health-service-retry SERVICE=resourcemanager
	@$(MAKE) up-service SERVICE=nodemanager1
	@$(MAKE) health-service-retry SERVICE=nodemanager1
	@$(MAKE) up-service SERVICE=nodemanager2
	@$(MAKE) health-service-retry SERVICE=nodemanager2
	@$(MAKE) up-service SERVICE=postgres
	@$(MAKE) health-service-retry SERVICE=postgres
	@$(MAKE) reset-metastore
	@$(MAKE) up-service SERVICE=metastore
	@$(MAKE) health-service-retry SERVICE=metastore
	@$(MAKE) up-service SERVICE=hiveserver2
	@$(MAKE) health-service-retry SERVICE=hiveserver2
	@$(MAKE) test
