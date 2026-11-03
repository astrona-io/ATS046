#!/usr/bin/env bash
# Check: shuttle reaches probe (by name, so DNS still works) and nothing else
# in the application. A request to scout through its Service and to the scout
# pod address must fail. Rejects a deny-all egress policy (probe must answer)
# and a policy that allows the whole namespace (scout must be refused).
set -uo pipefail

fail=0

if ! kubectl -n starfleet rollout status deployment/shuttle --timeout=120s >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment is not available"
  exit 1
fi

# http_code <url>: prints the HTTP status seen from the shuttle pod, or 000.
http_code() {
  kubectl -n starfleet exec deploy/shuttle -c shuttle -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 4 "$1" 2>/dev/null || true
}

got=""
for _ in $(seq 1 10); do
  got="$(http_code http://probe.starfleet.svc/get)"
  [ "$got" = "200" ] && break
  sleep 3
done
if [ "$got" != "200" ]; then
  echo "FAIL: shuttle must reach probe by name, got ${got:-no answer}"
  fail=1
fi

scout_ip="$(kubectl -n starfleet get pods -l app=scout -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true)"

# expect_refused <description> <url>
expect_refused() {
  local got=""
  for _ in $(seq 1 10); do
    got="$(http_code "$2")"
    [ "$got" != "200" ] && return 0
    sleep 3
  done
  echo "FAIL: shuttle can still reach $1"
  fail=1
}

expect_refused "the scout Service" http://scout.starfleet.svc/
if [ -n "$scout_ip" ]; then
  expect_refused "the scout pod address" "http://$scout_ip:9898/"
else
  echo "FAIL: the scout pod has no address"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle reaches probe only"
fi
exit "$fail"
