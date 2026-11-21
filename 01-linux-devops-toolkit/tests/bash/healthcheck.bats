#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/healthcheck.sh"
  SERVER_PID=""
}

teardown() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}

@test "passes when HTTP endpoint and port are up" {
  python3 -m http.server 8765 --bind 127.0.0.1 --directory "$BATS_TMPDIR" >/dev/null 2>&1 &
  SERVER_PID=$!
  sleep 1
  run "$SCRIPT" -u http://127.0.0.1:8765/ -p 127.0.0.1:8765
  [ "$status" -eq 0 ]
}

@test "fails when HTTP endpoint is down" {
  run "$SCRIPT" -t 2 -u http://127.0.0.1:9/
  [ "$status" -eq 1 ]
}

@test "fails when TCP port is closed" {
  run "$SCRIPT" -t 2 -p 127.0.0.1:1
  [ "$status" -eq 1 ]
}

@test "exit code 2 without checks" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
}
