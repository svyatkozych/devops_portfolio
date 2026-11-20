#!/usr/bin/env bats

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/backup.sh"
  SRC=$(mktemp -d)
  DEST=$(mktemp -d)
  echo hello > "$SRC/file.txt"
}

teardown() {
  rm -rf "$SRC" "$DEST"
}

@test "creates one archive" {
  run "$SCRIPT" "$SRC" "$DEST"
  [ "$status" -eq 0 ]
  [ "$(find "$DEST" -maxdepth 1 -name 'backup_*.tar.gz' -type f | wc -l)" -eq 1 ]
}

@test "rotation keeps only N newest" {
  for i in 1 2 3 4; do touch -d "$i days ago" "$DEST/backup_old$i.tar.gz"; done
  run "$SCRIPT" -k 2 "$SRC" "$DEST"
  [ "$status" -eq 0 ]
  [ "$(find "$DEST" -maxdepth 1 -name 'backup_*.tar.gz' -type f | wc -l)" -eq 2 ]
}

@test "fails on missing source" {
  run "$SCRIPT" /nonexistent "$DEST"
  [ "$status" -ne 0 ]
}

@test "dry run creates nothing" {
  run "$SCRIPT" -n "$SRC" "$DEST"
  [ "$status" -eq 0 ]
  [ -z "$(ls -A "$DEST")" ]
}

@test "exit code 2 without arguments" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
}
