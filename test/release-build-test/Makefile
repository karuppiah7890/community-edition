# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

.DEFAULT_GOAL:=help

# Inspired by Cluster-API Makefile
# Any target that has '## ' append to it will be included in the help message
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[0-9A-Za-z_-]+:.*?##/ { printf "  \033[36m%-45s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

get-deps: ## Get all dependencies
	go mod download

test:
	echo "N/A: No unit tests for test/release-build-test"

e2e-test:
	echo "N/A: No e2e tests for test/release-build-test"

lint: ## Run Go code linting
ifeq ($(origin GOLANGCI_LINT),undefined)
	@echo "Error! GOLANGCI_LINT env var not set"
else
	$(GOLANGCI_LINT) run -v --timeout=5m
endif
