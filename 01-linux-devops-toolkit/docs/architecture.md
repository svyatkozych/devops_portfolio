# Architecture

```mermaid
flowchart LR
  subgraph host[Linux host]
    T1[systemd timer: backup] --> B[scripts/backup.sh]
    T2[systemd timer: healthcheck] --> H[scripts/healthcheck.sh]
    H -- failure --> N[devtool notify]
    N --> TG[(Telegram)]
    L[nginx access log] --> P1[devtool logs - Python]
    L --> P2[logparser - C++]
    P1 --> R[report]
    P2 --> R
    U[users.csv] --> UP[scripts/user-provision.sh]
    C[scripts/log-cleanup.sh] --> L
  end

Design rules:

- Every Bash tool uses set -euo pipefail, has -h, predictable exit codes
  (0 success, 1 failed check, 2 bad usage) and a -n dry-run where it changes state.
- Shared helpers live in scripts/lib.sh.
- Python and C++ log analyzers print the same format, so parity is verified by diff.
- Configuration comes from environment files and variables, never from code.
