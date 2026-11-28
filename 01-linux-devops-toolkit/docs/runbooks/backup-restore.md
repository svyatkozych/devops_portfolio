# Runbook: backup and restore

## Check that backups run
    systemctl list-timers 'backup*' --no-pager
    journalctl -u backup.service -n 20 --no-pager
    ls -lh /var/backups/toolkit

## Run a backup manually
    sudo systemctl start backup.service

## Restore
cat > docs/runbooks/backup-restore.md <<'EOF'
# Runbook: backup and restore

## Check that backups run
    systemctl list-timers 'backup*' --no-pager
    journalctl -u backup.service -n 20 --no-pager
    ls -lh /var/backups/toolkit

## Run a backup manually
    sudo systemctl start backup.service

## Restore

  sudo mkdir -p /tmp/restore
    sudo tar -xzf /var/backups/toolkit/backup_<timestamp>.tar.gz -C /tmp/restore
    # verify the content, then copy it back

## Troubleshooting
| Symptom | Check | Fix |
|---|---|---|
| Timer not listed | `systemctl status backup.timer` | `sudo scripts/install.sh` |
| Service fails | `journalctl -u backup.service` | check `/etc/toolkit/backup.env` paths |
| Disk full | `df -h /var/backups` | lower `BACKUP_KEEP` |
