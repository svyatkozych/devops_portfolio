.RECIPEPREFIX = >
.DEFAUL_GOAL := help
.PHONY: help linttest lab-up lab-down

help: ## Show available targets
> @grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*##' '{printf "  %-10s %s\n", $$1, $$2}'

lint: ## Run shellcheck on all scripts
> shellcheck scripts/*.sh

test: ##Run bats tests
> bats tests/bash

lab-up: ## Start sandbox (Ubuntu) and nginx
> docker compose --profile lab up -d

lab-down: ## Stop and remove the lab
> docker compose --profile lab down -v
