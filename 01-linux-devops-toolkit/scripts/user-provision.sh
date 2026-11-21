#!/usr/bin/env bash
# user-provision.sh - create users from a CSV file. Idempotent.
# CSV columns: username,group,shell,sudo(yes/no),ssh_public_key
set -euo pipefail
trap 'echo "ERROR: failed at line $LINENO" >&2' ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<USAGE
Usage: sudo $(basename "$0") [-n] USERS.csv
  -n   dry run, change nothing (root not required)
  -h   show this help
USAGE
}

DRY=0
while getopts ':nh' opt; do
  case $opt in
    n) DRY=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
CSV=$1
[[ -f $CSV ]] || die "file not found: $CSV"
(( DRY )) || [[ $EUID -eq 0 ]] || die 'run as root (or use -n)' 2

run() {
  if (( DRY )); then log "[dry-run] $*"; else "$@"; fi
}

while IFS=, read -r user group shell sudo_flag pubkey; do
  [[ -z $user || $user == '#'* || $user == username ]] && continue
  if ! [[ $user =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    warn "invalid username skipped: $user"
    continue
  fi
  shell=${shell:-/bin/bash}

  if [[ -n $group ]] && ! getent group "$group" >/dev/null; then
    run groupadd "$group"
  fi

  if id "$user" >/dev/null 2>&1; then
    log "user exists: $user"
  else
    if [[ -n $group ]]; then
      run useradd -m -s "$shell" -g "$group" "$user"
    else
      run useradd -m -s "$shell" "$user"
    fi
    log "user processed: $user"
  fi

  if [[ $sudo_flag == yes ]]; then
    run usermod -aG sudo "$user"
  fi

  if [[ -n $pubkey ]] && (( ! DRY )); then
    home=$(getent passwd "$user" | cut -d: -f6)
    pgroup=$(id -gn "$user")
    install -d -m 700 -o "$user" -g "$pgroup" "$home/.ssh"
    touch "$home/.ssh/authorized_keys"
    grep -qxF "$pubkey" "$home/.ssh/authorized_keys" || echo "$pubkey" >> "$home/.ssh/authorized_keys"
    chown "$user:$pgroup" "$home/.ssh/authorized_keys"
    chmod 600 "$home/.ssh/authorized_keys"
  fi
done < "$CSV"

log 'done'
