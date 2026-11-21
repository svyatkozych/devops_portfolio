#!/usr/bin/env bash
# install.sh - install toolkit scripts and systemd timers.
set -euo pipefail
trap 'echo "ERROR: failed at line $LINENO" >&2' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

PREFIX=/opt/toolkit
UNIT_DIR=/etc/systemd/system
CONF_DIR=/etc/toolkit
TIMERS=(backup.timer healthcheck.timer)

usage() {
  cat <<USAGE
Usage: sudo $(basename "$0") [-u] [-n]
  -u   uninstall (config in $CONF_DIR is kept)
  -n   dry run, change nothing
  -h   show this help
USAGE
}

UNINSTALL=0
DRY=0
while getopts ':unh' opt; do
  case $opt in
    u) UNINSTALL=1 ;;
    n) DRY=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

(( DRY )) || [[ $EUID -eq 0 ]] || die 'run as root (or use -n)' 2

run() {
  if (( DRY )); then log "[dry-run] $*"; else "$@"; fi
}

write_default() {
  local file=$1 content=$2
  if [[ -e $file ]]; then
    log "keeping existing $file"
  elif (( DRY )); then
    log "[dry-run] create $file"
  else
    printf '%s\n' "$content" > "$file"
    log "created $file"
  fi
}

if (( UNINSTALL )); then
  for t in "${TIMERS[@]}"; do
    run systemctl disable --now "$t" || true
  done
  for u in "$SCRIPT_DIR"/systemd/*.service "$SCRIPT_DIR"/systemd/*.timer; do
    run rm -f "$UNIT_DIR/$(basename "$u")"
  done
  run rm -rf "$PREFIX"
  run systemctl daemon-reload
  log 'uninstalled'
  exit 0
fi

run install -d -m 755 "$PREFIX/scripts" "$CONF_DIR"
for f in "$SCRIPT_DIR"/*.sh; do
  [[ $(basename "$f") == install.sh ]] && continue
  run install -m 755 "$f" "$PREFIX/scripts/"
done
for u in "$SCRIPT_DIR"/systemd/*.service "$SCRIPT_DIR"/systemd/*.timer; do
  run install -m 644 "$u" "$UNIT_DIR/"
done

write_default "$CONF_DIR/backup.env" 'BACKUP_SRC=/etc/toolkit
BACKUP_DEST=/var/backups/toolkit
BACKUP_KEEP=7'
write_default "$CONF_DIR/healthcheck.env" 'HEALTH_ARGS=-s ssh'

run systemctl daemon-reload
for t in "${TIMERS[@]}"; do
  run systemctl enable --now "$t"
done
log 'installed. See: systemctl list-timers'
