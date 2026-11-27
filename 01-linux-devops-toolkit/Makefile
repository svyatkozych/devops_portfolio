SHELL := /bin/bash
.RECIPEPREFIX = >
.DEFAULT_GOAL := help
LOG ?= tests/data/access.log

.PHONY: help lint lint-bash lint-py test test-bash test-py cpp-build cpp-test parity bench lab-up lab-down

help: ## Show available targets
> @grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

lint: lint-bash lint-py ## Run all linters

lint-bash: ## shellcheck on all scripts
> shellcheck scripts/*.sh

lint-py: ## ruff on Python code
> ruff check src tests/python

test: test-bash test-py cpp-test ## Run all tests

test-bash: ## bats tests
> bats tests/bash

test-py: ## pytest with coverage
> pytest --cov=devtool

cpp-build: ## Build the C++ logparser into ./build
> cmake -S src/logparser -B build -DCMAKE_BUILD_TYPE=Release
> cmake --build build

cpp-test: cpp-build ## Run ctest for the C++ parser
> ctest --test-dir build --output-on-failure

parity: cpp-build ## C++ and Python must give identical output (LOG=file)
> diff <(build/logparser $(LOG)) <(devtool logs $(LOG)) && echo 'parity OK'

bench: cpp-build ## Benchmark C++ vs Python, writes docs/benchmarks.md
> scripts/benchmark.sh

lab-up: ## Start sandbox (Ubuntu) and nginx
> docker compose --profile lab up -d

lab-down: ## Stop and remove the lab
> docker compose --profile lab down -v
