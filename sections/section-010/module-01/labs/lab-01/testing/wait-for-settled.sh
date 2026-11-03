#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the old
# pods are gone and the RBAC answer for shuttle has changed.
set -euo pipefail

for i in $(seq 1 30); do
  answer="$(kubectl auth can-i '*' '*' -n starfleet --as=system:serviceaccount:starfleet:shuttle 2>/dev/null || true)"
  terminating="$(kubectl -n starfleet get pods -o json | jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length')"
  if [ "$answer" = "no" ] && [ "$terminating" = "0" ]; then
    echo "[testing] settled."
    exit 0
  fi
  sleep 2
done
echo "[testing] the cluster did not settle in time." >&2
exit 1
