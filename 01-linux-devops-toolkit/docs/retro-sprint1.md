# Sprint 1 retrospective

## Done
- Scaffold, CI, backup, healthcheck, log-cleanup, user-provision, systemd timers.

## What went well
- Built a clean foundational structure for scripts, checks, and automated tests early in the sprint.
- Separated runtime configuration (`/etc/toolkit/*.env`) from executable scripts and `systemd` unit definitions.
- Verified real execution of `backup.service` and confirmed archive creation in `/var/backups/toolkit/`.

## What did not
- Confusion between source files in the repository and deployed copies in `/opt/toolkit/scripts/` and `/etc/systemd/system/`.
- In `backup.service`, `${BACKUP_KEEP:-7}` inside `ExecStart` was passed literally rather than expanded, causing `KEEP` validation to fail (`status=2`).

## Next sprint
- devtool (Python): logs, ssl, sys, notify
- C++ logparser, benchmarks, release v1.0.0
