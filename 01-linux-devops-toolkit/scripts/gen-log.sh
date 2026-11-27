#!/usr/bin/env bash
# gen-log.sh - print N synthetic nginx access-log lines to stdout (deterministic).
set -euo pipefail

N=${1:-100000}
[[ $N =~ ^[0-9]+$ ]] || { echo "Usage: $(basename "$0") [LINES]" >&2; exit 2; }

awk -v n="$N" 'BEGIN {
  srand(42)
  split("200 200 200 200 201 301 302 404 500 502", st, " ")
  split("/ /api/tasks /api/tasks/1 /login /static/app.js /missing", pa, " ")
  for (i = 0; i < n; i++) {
    printf "%d.%d.%d.%d - - [10/Nov/2026:10:%02d:%02d +0000] \"GET %s?id=%d HTTP/1.1\" %s %d \"-\" \"bench\"\n", \
      10 + int(rand() * 3), int(rand() * 10), int(rand() * 10), 1 + int(rand() * 50), \
      int(rand() * 60), int(rand() * 60), pa[1 + int(rand() * 6)], int(rand() * 1000), \
      st[1 + int(rand() * 10)], int(rand() * 5000)
  }
}'
