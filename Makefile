# -------------
# VARIABLES
# -------------

# Detect the operating system, architecture, and container runtime.

include makefiles/osdetect.mk

# Git variables

GIT_REPOSITORY_NAME := $(shell basename `git rev-parse --show-toplevel`)
GIT_VERSION := $(shell git describe --always --tags --long --dirty | sed -e 's/\-0//' -e 's/\-g.......//')

# Docker variables

DOCKER_IMAGE_TAG ?= $(GIT_REPOSITORY_NAME):$(GIT_VERSION)
DOCKER_IMAGE_NAME := senzing-factory/github-action-slack-notification

# -------------
# TASKS
# -------------
.PHONY: fmt
fmt:
	@gofmt -w -s -d configuration
	@gofmt -w -s -d main.go

.PHONY: build
build: fmt
	@go mod download && \
     go get ./... && \
     go install ./...

# -----------------------------------------------------------------------------
# The first "make" target runs as default.
# -----------------------------------------------------------------------------

.PHONY: default
default: help

# -----------------------------------------------------------------------------
# Docker-based builds
# -----------------------------------------------------------------------------

$(eval $(call container_build_target,docker-build,,$(GIT_VERSION)))
docker-build: docker-rmi-for-build

.PHONY: docker-build-development-cache
docker-build-development-cache: docker-rmi-for-build-development-cache
	$(CONTAINER_RUNTIME) build \
		--tag $(DOCKER_IMAGE_TAG) \
		.

# -----------------------------------------------------------------------------
# Clean up targets
# -----------------------------------------------------------------------------

.PHONY: docker-rmi-for-build
docker-rmi-for-build:
	-$(CONTAINER_RMI) \
		$(DOCKER_IMAGE_NAME):$(GIT_VERSION) \
		$(DOCKER_IMAGE_NAME)

.PHONY: docker-rmi-for-build-development-cache
docker-rmi-for-build-development-cache:
	-$(CONTAINER_RMI) $(DOCKER_IMAGE_TAG)

.PHONY: clean
clean: docker-rmi-for-build docker-rmi-for-build-development-cache

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

.PHONY: help
help:
	@echo "List of make targets:"
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
