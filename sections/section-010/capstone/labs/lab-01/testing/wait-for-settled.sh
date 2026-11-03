#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the old
# pods in orbit are gone.
set -euo pipefail

for i in $(seq 1 30); do
  terminating="$(kubectl -n orbit get pods -o json | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length')"
  if [ "$terminating" = "0" ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] old pods did not terminate in time." >&2
exit 1
