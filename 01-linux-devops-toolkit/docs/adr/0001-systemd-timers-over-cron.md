# ADR 0001: systemd timers instead of cron

Status: accepted

## Context
Scheduled jobs (backup, health checks) need logging, failure visibility and catch-up after downtime.

## Desicion
Use systemd service and timer units.

## Consequences
- Logs in journald; Persistent=true runs missed jobs.
- Dependencies and hardening options are declarative.
- More files than a single cron line; units live in scripts/systemd/.
