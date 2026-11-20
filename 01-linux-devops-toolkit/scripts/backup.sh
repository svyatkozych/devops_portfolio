#!/usr/bin/env bash
# backup.sh - create a timestamped tar.gz backup and rotate old ones.
set -euo pipefail
trap 'echo "Error: failed at line $LINENO" >&2' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-k KEEP] [-n] SRC DEST
  -k KEEP  number of backups to keep (default 7)
  -n       dry run, change nothing
  -h       show this help
USAGE
}

KEEP=7
DRY=0
while getopts ':k:nh' opt; do
  case $opt in
    k) KEEP=$OPTARG ;;
    n) DRY=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ $# -eq 2 ]] || { usage >&2; exit 2; }
SRC=$1
DEST=$2


[[ -d $SRC ]] || die "source is not a directory: $SRC"
[[ $KEEP =~ ^[0-9]+$ && $KEEP -ge 1 ]] || die 'KEEP must be a positive integer' 2

(( DRY )) || mkdir -p "$DEST"
TS=$(date +%F_%H%M%S)
ARCHIVE="$DEST/backup_${TS}.tar.gz"

if (( DRY )); then
  log "[dry-run] would create $ARCHIVE"
else
  tar -czf "$ARCHIVE" -C "$SRC" .
  log "created $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
fi

mapfile -t old < <(find "$DEST" -maxdepth 1 -name "backup_*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2- | tail -n +"$((KEEP + 1))" || true)
for f in "${old[@]}"; do
  if (( DRY )); then
    log "[dry-run] would delete $f"
  else
    rm -- "$f"
    log "deleted old backup $f"
  fi
done
