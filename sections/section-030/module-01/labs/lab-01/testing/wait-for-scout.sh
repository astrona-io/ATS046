#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# evidence ConfigMap exists.
set -uo pipefail

for _ in $(seq 1 30); do
  if kubectl -n starfleet get configmap scout-release-evidence >/dev/null 2>&1; then
    echo "[testing] Evidence record found."
    exit 0
  fi
  sleep 2
done
echo "[testing] The evidence record was not created." >&2
exit 1
