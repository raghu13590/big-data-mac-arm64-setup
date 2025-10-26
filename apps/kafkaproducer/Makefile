# KafkaProducer  Makefile delegating to Top-Level Makefile.common
.PHONY: up down build restart logs clean status health

include ../Makefile.common

SAMPLE_MESSAGE_DIR := ../../app-data/kafkaproducer/messages
SAMPLE_MESSAGE_FILE := $(SAMPLE_MESSAGE_DIR)/samplemessage.txt

.PHONY: create-sample-message

up:
	@$(MAKE) render
	@$(MAKE) dependencies
	@$(MAKE) build-no-cache
	@$(MAKE) create-sample-message
	@$(MAKE) up-service-health SERVICE=kafkaproducer

create-sample-message:
	mkdir -p $(SAMPLE_MESSAGE_DIR)
	echo "sample message at <timestamp> with id : <id>" > $(SAMPLE_MESSAGE_FILE)
	@echo "Created sample message file: $(SAMPLE_MESSAGE_FILE)"
