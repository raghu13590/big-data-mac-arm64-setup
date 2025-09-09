# Zoonavigator Makefile delegating to Top-Level Makefile.common
.PHONY: up down build restart logs clean status health

ifneq (,$(wildcard .env))
    include .env
    export
endif

include ../Makefile.common

up:
	@echo "Checking Zookeeper health..."
	@if $(MAKE) -C ../zookeeper health; then echo "Zookeeper is healthy, proceeding to start Pinot"; \
	else \
		echo "Zookeeper not healthy, starting..."; \
		$(MAKE) -C ../zookeeper up; \
		$(MAKE) -C ../zookeeper health || (echo "Zookeeper failed to start"; exit 1); \
	fi
	@$(MAKE) -f ../Makefile.common up