# apps/flink/Makefile

# Include the common Makefile
include ../Makefile.common

up:
	@$(MAKE) render
	@$(MAKE) dependencies
	@$(MAKE) up-service-health SERVICE=jobmanager
	@$(MAKE) up-service-health SERVICE=taskmanager
	@$(MAKE) test

test:
	@$(CURDIR)/tests.sh