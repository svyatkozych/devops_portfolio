# 01. Linux DevOps Toolkit

![CI](https://github.com/svyatkozych/devops_portfolio/actions/workflows/01-toolkit.yml/badge.svg)

Bash, Python and C++ utilities for everyday DevOps tasks on Linux: backups with rotation, health checks, log cleanup, idempotent user provisioning, log analysis and Telegram alerts.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25)
![Python](https://img.shields.io/badge/python-3.12-3776AB)
![C++](https://img.shields.io/badge/c%2B%2B-17-00599C)
![Platform](https://img.hields.io/badge/platform-Ubuntu%2024.04-E95420)

## Why

Routine operations are often done with ad-hoc commands. This toolkit turns them into
tested, documented and scheduled tools with predictable exit codes, dry-run modes and CI.

## Layout

- 'scripts/' Bash tools and systemd units
- 'src/' Python package (devtool) and C++ parser (logparser)
- 'tests/' bats and pytest tests, sample data
- 'docs/' architecture desicions, runbooks, benchmarks

## Quick start

    make help
    make test

Progress: [README_STATUS.md](README_STATUS.md).
