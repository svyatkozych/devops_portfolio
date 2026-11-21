#!/usr/bin/env bash
# Common helpers. Source this file, do not execute it.

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { log "WARN: $*" >&2; }
die() { log "ERROR": "$1" >&2; exit "${2:-1}"; }
