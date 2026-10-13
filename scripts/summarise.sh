#!/usr/bin/env bash
# Purpose: summarise a saved monitor log (Task 4).
# Usage:   bash scripts/summarise.sh evidence/t4-at-rest.log
# Input line format: <ISO-8601 timestamp> <OK|FAIL> <response body or error>
set -eu

# Exactly one argument (the log file) is required.
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "usage: $0 <monitor-log>" >&2
  exit 1
fi

# Strip Windows CR characters (PowerShell redirection may add them) before parsing.
tr -d '\r' < "$1" | awk '
  NF >= 2 && ($2 == "OK" || $2 == "FAIL") {
    total++
    if (!first) first = $1
    last = $1
    if ($2 == "FAIL") { failed++ }
    else {
      # Pull the value of the "version" key out of the JSON body.
      v = "unknown"
      if (match($0, /"version": *"[^"]*"/)) {
        s = substr($0, RSTART, RLENGTH)
        sub(/^"version": *"/, "", s); sub(/"$/, "", s)
        v = s
      }
      count[v]++
    }
  }
  END {
    printf "total requests:  %d\n", total
    printf "failed requests: %d\n", failed
    printf "first timestamp: %s\n", first
    printf "last timestamp:  %s\n", last
    print  "responses per version:"
    for (v in count) printf "  %s: %d\n", v, count[v]
  }'