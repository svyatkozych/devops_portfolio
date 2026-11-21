#!/usr/bin/env bash
# healthcheck.sh - check HTTP endpoints, TCP ports and systemd services.
# Exit code: 0 = all checks passed, 1 = at least one failed, 2 = bad usage.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-u URL]... [-p HOST:PORT]... [-s SERVICE]... [-t SECONDS]
  -u URL       HTTP(S) endpoint, OK if status is 2xx or 3xx
  -p HOST:PORT TCP port must accept connections
  -s SERVICE   systemd service must be active
  -t SECONDS   timeout per check (default 5)
USAGE
}

URLS=()
PORTS=()
SERVICES=()
TIMEOUT=5
while getopts ':u:p:s:t:h' opt; do
  case $opt in
    u) URLS+=("$OPTARG") ;;
    p) PORTS+=("$OPTARG") ;;
    s) SERVICES+=("$OPTARG") ;;
    t) TIMEOUT=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

(( ${#URLS[@]} + ${#PORTS[@]} + ${#SERVICES[@]} > 0 )) || { usage >&2; exit 2; }

FAILED=0
pass() { log "OK    $*"; }
fail() { log "FAIL  $*"; FAILED=$((FAILED + 1)); }

for url in "${URLS[@]}"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$url" || true)
  if [[ $code =~ ^[23] ]]; then pass "http $url ($code)"; else fail "http $url (${code:-no response})"; fi
done

for hp in "${PORTS[@]}"; do
  host=${hp%:*}
  port=${hp##*:}
  if timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
    pass "tcp $hp"
  else
    fail "tcp $hp"
  fi
done

for svc in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then pass "service $svc"; else fail "service $svc"; fi
done

(( FAILED == 0 )) || { log "$FAILED check(s) failed"; exit 1; }
log 'all checks passed'
