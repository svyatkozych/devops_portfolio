#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/user-provision.sh"
  CSV="$BATS_TEST_DIRNAME/../data/users.csv"
}

@test "dry run lists planned actions" {
  run "$SCRIPT" -n "$CSV"
  [ "$status" -eq 0 ]
  [[ $output == *'[dry-run] useradd'* ]]
}

@test "fails on missing csv" {
  run "$SCRIPT" -n /nonexistent.csv
  [ "$status" -ne 0 ]
}

@test "requires root without dry run" {
  [ "$EUID" -ne 0 ] || skip 'running as root'
  run "$SCRIPT" "$CSV"
  [ "$status" -eq 2 ]
}
