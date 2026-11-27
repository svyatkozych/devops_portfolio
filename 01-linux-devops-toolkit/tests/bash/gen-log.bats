#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/gen-log.sh"
}

@test "generates the requested number of lines" {
  run bash -c "$SCRIPT 100 | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -eq 100 ]
}

@test "output is deterministic" {
  a=$("$SCRIPT" 50 | md5sum)
  b=$("$SCRIPT" 50 | md5sum)
  [ "$a" = "$b" ]
}

@test "rejects non-numeric argument" {
  run "$SCRIPT" abc
  [ "$status" -eq 2 ]
}
