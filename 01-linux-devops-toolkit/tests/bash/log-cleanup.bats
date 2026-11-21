#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/log-cleanup.sh"
  DIR=$(mktemp -d)
  touch -d '30 days ago' "$DIR/old.log"
  touch "$DIR/new.log"
}

teardown() {
  rm -rf "$DIR"
}

@test "deletes only old logs" {
  run "$SCRIPT" -d 14 "$DIR"
  [ "$status" -eq 0 ]
  [ ! -e "$DIR/old.log" ]
  [ -e "$DIR/new.log" ]
}

@test "dry run keeps everything" {
  run "$SCRIPT" -n -d 14 "$DIR"
  [ "$status" -eq 0 ]
  [ -e "$DIR/old.log" ]
}

@test "refuses dangerous directory" {
  run "$SCRIPT" /etc
  [ "$status" -eq 2 ]
}

@test "fails on missing directory" {
  run "$SCRIPT" /nonexistent-dir-xyz
  [ "$status" -ne 0 ]
}
