#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# network plugin enforces the shuttle egress policy.
set -euo pipefail

for _ in $(seq 1 30); do
  code="$(kubectl -n starfleet exec deploy/shuttle -c shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://scout.starfleet.svc/ 2>/dev/null || true)"
  if [ "$code" != "200" ]; then
    echo "[testing] shuttle egress policy is enforced."
    exit 0
  fi
  sleep 2
done
echo "[testing] shuttle egress policy was not enforced in time." >&2
exit 1
