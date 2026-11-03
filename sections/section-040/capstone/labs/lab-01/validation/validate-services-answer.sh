#!/usr/bin/env bash
# Check: behaviour. shuttle reaches scout and probe, so the fixes did not break
# the workloads.
set -uo pipefail

scout_code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout.starfleet.svc.cluster.local/healthz 2>/dev/null || true)"
if [ "$scout_code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${scout_code}' from scout, expected 200"
  exit 1
fi

probe_code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://probe.starfleet.svc.cluster.local/get 2>/dev/null || true)"
if [ "$probe_code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${probe_code}' from probe, expected 200"
  exit 1
fi

echo "PASS: shuttle reaches scout and probe (HTTP 200)"
