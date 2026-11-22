.RECIPEPREFIX = >
.DEFAULT_GOAL := help
.PHONY: help lint lint-bash lint-py test test-bash test-py lab-up lab-down

help: ## Show available targets
> @grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

lint: lint-bash lint-py ## Run all linters

lint-bash: ## shellcheck on all scripts
> shellcheck scripts/*.sh

lint-py: ## ruff on Python code
> ruff check src tests/python

test: test-bash test-py ## Run all tests

test-bash: ## bats tests
> bats tests/bash

test-py: ## pytest with coverage
> pytest --cov=devtool

lab-up: ## Start sandbox (Ubuntu) and nginx
> docker compose --profile lab up -d

lab-down: ## Stop and remove the lab
> docker compose --profile lab down -v
