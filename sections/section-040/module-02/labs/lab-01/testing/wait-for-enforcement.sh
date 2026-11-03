#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until Kyverno
# rejects a privileged pod and the API server rejects a Deployment without an
# owner label in starfleet.
set -uo pipefail

for i in $(seq 1 60); do
  if ! kubectl -n starfleet run wait-priv --image=curlimages/curl:8.22.0 --privileged=true --dry-run=server -o name >/dev/null 2>&1; then
    break
  fi
  sleep 3
done

for i in $(seq 1 60); do
  if ! kubectl -n starfleet create deployment wait-owner --image=curlimages/curl:8.22.0 --dry-run=server -o name >/dev/null 2>&1; then
    echo "[testing] Both policies reject bad requests."
    sleep 3
    exit 0
  fi
  sleep 3
done
echo "[testing] The policies did not reject bad requests in time." >&2
exit 1
