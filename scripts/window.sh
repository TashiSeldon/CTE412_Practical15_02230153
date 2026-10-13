#!/usr/bin/env bash
# Purpose: measure the mixed-version window and the failure window in a release log (Task 5).
# Usage:   bash scripts/window.sh <monitor-log> <old-version> <new-version>
# Note:    log timestamps have 1-second resolution, so results are accurate to about +/- 1 s.
set -eu

if [ "$#" -ne 3 ] || [ ! -f "$1" ]; then
  echo "usage: $0 <monitor-log> <old-version> <new-version>" >&2
  exit 1
fi
log=$1; old=$2; new=$3

# Clean copy without Windows carriage returns.
clean=$(tr -d '\r' < "$log")

# First response from the new version, last response from the old version.
first_new=$(printf '%s\n' "$clean" | grep "\"version\": \"$new\"" | head -1 | cut -d' ' -f1 || true)
last_old=$(printf '%s\n' "$clean" | grep "\"version\": \"$old\"" | tail -1 | cut -d' ' -f1 || true)
# First and last failed request, and how many failed.
first_fail=$(printf '%s\n' "$clean" | grep ' FAIL ' | head -1 | cut -d' ' -f1 || true)
last_fail=$(printf '%s\n' "$clean" | grep ' FAIL ' | tail -1 | cut -d' ' -f1 || true)
fails=$(printf '%s\n' "$clean" | grep -c ' FAIL ' || true)

echo "failed requests:       $fails"
if [ -n "$first_fail" ]; then
  d=$(( $(date -u -d "$last_fail" +%s) - $(date -u -d "$first_fail" +%s) ))
  echo "first FAIL:            $first_fail"
  echo "last FAIL:             $last_fail"
  echo "failure window:        $d s"
else
  echo "failure window:        none"
fi
echo "first $new response: ${first_new:-none}"
echo "last $old response:  ${last_old:-none}"
if [ -n "$first_new" ] && [ -n "$last_old" ]; then
  m=$(( $(date -u -d "$last_old" +%s) - $(date -u -d "$first_new" +%s) ))
  [ "$m" -lt 0 ] && m=0
  echo "mixed-version window:  $m s (0 = the two versions never overlapped)"
else
  echo "mixed-version window:  not measurable (one version missing from the log)"
fi