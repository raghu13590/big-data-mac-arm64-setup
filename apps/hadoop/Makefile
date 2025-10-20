# apps/hadoop/Makefile

include ../Makefile.common

.PHONY: build-hadoop format-namenode clean-hadoop reset-metastore init-metastore reset-hive-warehouse up up-reset test

format-namenode:
	@echo "$(GREEN)Formatting Hadoop NameNode...$(NC)"
	$(DOCKER_COMPOSE) run --rm namenode hdfs namenode -format -force

clean-hadoop:
	@echo "$(RED)Stopping all Hadoop containers and removing volumes...$(NC)"
	@$(DOCKER_COMPOSE) down -v
	@services="$$( $(DOCKER_COMPOSE) config --services)"; \
	for service in $$services; do \
		echo "$(RED)Clearing $(APP_DATA_DIR)/$$service data...$(NC)"; \
		if [ -d $(APP_DATA_DIR)/$$service ]; then \
			find $(APP_DATA_DIR)/$$service -mindepth 1 -delete; \
		fi; \
	done

init-datanodes:
	@$(DOCKER_COMPOSE) run --rm datanode1 bash -c "mkdir -p /hadoop/dfs/data"
	@$(DOCKER_COMPOSE) run --rm datanode2 bash -c "mkdir -p /hadoop/dfs/data"

init-metastore:
	@echo "$(GREEN)Initializing Hive metastore schema if needed...$(NC)"
	@if [ "$$($(DOCKER_COMPOSE) exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then \
		$(DOCKER_COMPOSE) exec metastore sh -c '$$HIVE_HOME/bin/schematool -dbType postgres -initSchema'; \
	else \
		echo "Metastore schema already exists. Skipping initialization."; \
	fi

reset-metastore:
	@echo "$(GREEN)Resetting Hive metastore database...$(NC)"
	@if $(DOCKER_COMPOSE) exec postgres psql -U hive -d postgres -lqt | cut -d \| -f 1 | grep -qw metastore; then \
		$(DOCKER_COMPOSE) exec postgres psql -U hive -d postgres -c "DROP DATABASE metastore;"; \
	fi
	$(DOCKER_COMPOSE) exec postgres psql -U hive -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'metastore';" | grep -q 1 || \
		$(DOCKER_COMPOSE) exec postgres psql -U hive -d postgres -c "CREATE DATABASE metastore;"
	@if [ "$$($(DOCKER_COMPOSE) exec -T postgres bash -c 'ls -A /var/lib/postgresql/data | wc -l')" -eq 0 ]; then \
		$(DOCKER_COMPOSE) exec metastore sh -c '$$HIVE_HOME/bin/schematool -dbType postgres -initSchema'; \
	else \
		echo "Metastore schema already exists. Skipping initialization."; \
	fi

test:
	@$(CURDIR)/tests.sh

up: ## Start Hadoop services (normal flow, no reset)
	@$(MAKE) render
	@$(MAKE) dependencies
	@$(MAKE) up-service-health SERVICE=namenode
	@$(MAKE) up-service-health SERVICE=datanode1
	@$(MAKE) up-service-health SERVICE=datanode2
	@$(MAKE) up-service-health SERVICE=resourcemanager
	@$(MAKE) up-service-health SERVICE=nodemanager1
	@$(MAKE) up-service-health SERVICE=nodemanager2
	@$(MAKE) up-service-health SERVICE=postgres
	@$(MAKE) up-service-health SERVICE=metastore
	@$(MAKE) init-metastore
	@$(MAKE) up-service-health SERVICE=hiveserver2
	@$(MAKE) test

up-reset: ## Perform a full clean install and start Hadoop services
	@$(MAKE) render
	@$(MAKE) dependencies
	@$(MAKE) build-quick
	@$(MAKE) clean-hadoop
	@$(MAKE) format-namenode
	@$(MAKE) up-service-health SERVICE=namenode
	@$(MAKE) init-datanodes
	@$(MAKE) up-service-health SERVICE=datanode1
	@$(MAKE) up-service-health SERVICE=datanode2
	@$(MAKE) up-service-health SERVICE=resourcemanager
	@$(MAKE) up-service-health SERVICE=nodemanager1
	@$(MAKE) up-service-health SERVICE=nodemanager2
	@$(MAKE) up-service-health SERVICE=postgres
	@$(MAKE) reset-metastore
	@$(MAKE) up-service-health SERVICE=metastore
	@$(MAKE) up-service-health SERVICE=hiveserver2
	@$(MAKE) test
