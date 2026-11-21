#!/usr/bin/env bash
# log-cleanup.sh - delete old log files from a directory.
set -euo pipefail
trap 'echo "ERROR: failed at line $LINENO" >&2' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-d DAYS] [-n] DIR
  -d DAYS  delete files older than DAYS (default 14)
  -n       dry run, change nothing
  -h       show this help
USAGE
}

DAYS=14
DRY=0
while getopts ':d:nh' opt; do
  case $opt in
    d) DAYS=$OPTARG ;;
    n) DRY=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
DIR=${1%/}
DIR=${DIR:-/}

[[ $DAYS =~ ^[0-9]+$ ]] || die 'DAYS must be a number' 2
case $DIR in
  /|/etc|/usr|/bin|/sbin|/boot|/home|/root|/lib|/var) die "refusing to clean $DIR" 2 ;;
esac
[[ -d $DIR ]] || die "not a directory: $DIR"

count=0
while IFS= read -r -d '' f; do
  if (( DRY )); then
    log "[dry-run] would delete $f"
  else
    rm -- "$f"
    log "deleted $f"
  fi
  count=$((count + 1))
done < <(find "$DIR" -type f \( -name '*.log' -o -name '*.log.*' -o -name '*.gz' \) -mtime +"$DAYS" -print0)

log "processed $count file(s)"
