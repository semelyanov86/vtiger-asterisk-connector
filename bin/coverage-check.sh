#!/usr/bin/env bash
# Coverage gate. Reads the line threshold from .coverage-thresholds.json,
# runs the Go test suite with coverage, and fails if total coverage is below it.
# Single source of truth: .coverage-thresholds.json
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG=".coverage-thresholds.json"
PROFILE="${COVERAGE_PROFILE:-coverage.out}"

if [ ! -f "$CONFIG" ]; then
  echo "coverage-check: $CONFIG not found" >&2
  exit 1
fi

threshold="$(
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["thresholds"]["lines"])' "$CONFIG"
)"

go test -coverprofile="$PROFILE" -covermode=atomic ./...

if [ ! -s "$PROFILE" ]; then
  echo "coverage-check: no coverage profile produced" >&2
  exit 1
fi

total="$(go tool cover -func="$PROFILE" | awk '/^total:/ {gsub(/%/, "", $3); print $3}')"

if [ -z "$total" ]; then
  echo "coverage-check: could not parse total coverage" >&2
  exit 1
fi

awk -v t="$total" -v min="$threshold" 'BEGIN {
  if (t + 0 < min + 0) {
    printf "FAIL: total coverage %.1f%% is below the %s%% threshold\n", t, min
    exit 1
  }
  printf "OK: total coverage %.1f%% (threshold %s%%)\n", t, min
}'
