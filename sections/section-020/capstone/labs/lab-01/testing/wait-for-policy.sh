#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# network plugin enforces the probe policy, so the validation scripts do not
# race the plugin.
set -euo pipefail

for _ in $(seq 1 30); do
  code="$(kubectl -n outpost exec deploy/drifter -c drifter -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://probe.starfleet.svc/get 2>/dev/null || true)"
  if [ "$code" != "200" ]; then
    echo "[testing] probe policy is enforced."
    exit 0
  fi
  sleep 2
done
echo "[testing] probe policy was not enforced in time." >&2
exit 1
