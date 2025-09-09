# Zookeeper Makefile.common delegating to Top-Level Makefile.common
.PHONY: up down build restart logs clean status health

include ../Makefile.common

health:
	@services=$$(docker compose -f docker-compose.yml config --services); \
	for svc in $$services; do \
		echo "$${YELLOW}Checking health of $$svc...$${NC}"; \
		status_output=$$(docker exec $$svc zkServer.sh status 2>&1); \
		mode=$$(echo "$$status_output" | grep -oE 'Mode: (leader|follower|standalone)'); \
		if [ -n "$$mode" ]; then :; \
		else \
			echo "$${RED}Error: Could not determine mode for $$svc.$${NC}"; \
			exit 1; \
		fi; \
		if ! echo "$$status_output" | grep -E "Client port found|Mode"; then \
			echo "$${RED}Error: $$svc is not healthy.$${NC}"; \
			exit 1; \
		fi; \
		admin_port=$$(echo $$svc | grep -oE '[0-9]+'); \
		admin_url="http://localhost:808$$admin_port/commands"; \
		if ! curl -sSf "$$admin_url" > /dev/null; then \
			echo "$${RED}Error: AdminServer for $$svc is not accessible.$${NC}"; \
			exit 1; \
		fi; \
	done