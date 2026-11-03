#!/usr/bin/env bash
# Check: only the shuttle pods reach probe. A pod named caller in the same
# namespace and the drifter pod in outpost must be refused. Rejects a
# deny-all policy (shuttle must still work) and a policy that allows the whole
# starfleet namespace (caller must be refused).
set -uo pipefail

fail=0

# http_code <namespace> <deployment> <url>
# Prints the HTTP status, or 000 when the connection failed or timed out.
http_code() {
  kubectl -n "$1" exec "deploy/$2" -c "$2" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 4 "$3" 2>/dev/null || true
}

# expect_reach <description> <namespace> <deployment>
expect_reach() {
  local got=""
  for _ in $(seq 1 10); do
    got="$(http_code "$2" "$3" http://probe.starfleet.svc/get)"
    [ "$got" = "200" ] && return 0
    sleep 3
  done
  echo "FAIL: $1 must reach probe, got ${got:-no answer}"
  fail=1
}

# expect_refused <description> <namespace> <deployment>
expect_refused() {
  local got=""
  for _ in $(seq 1 10); do
    got="$(http_code "$2" "$3" http://probe.starfleet.svc/get)"
    [ "$got" != "200" ] && return 0
    sleep 3
  done
  echo "FAIL: $1 can still reach probe"
  fail=1
}

expect_reach "shuttle in starfleet" starfleet shuttle
expect_refused "caller in starfleet" starfleet caller
expect_refused "drifter in outpost" outpost drifter

if [ "$fail" -eq 0 ]; then
  echo "PASS: probe accepts requests from shuttle only"
fi
exit "$fail"
