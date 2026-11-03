#!/usr/bin/env bash
# Check: the fixes did not remove the workloads. Rejects deleting a Deployment,
# scaling it to zero or swapping the image.
set -uo pipefail

fail=0

expect_available() {
  local name="$1"
  local image="$2"
  local ready actual
  ready="$(kubectl -n orbit get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
  actual="$(kubectl -n orbit get deployment "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ "$actual" != "$image" ]; then
    echo "FAIL: deployment $name runs image '$actual', expected '$image'"
    fail=1
  fi
}

expect_available beacon ghcr.io/stefanprodan/podinfo:6.15.0
expect_available relay curlimages/curl:8.22.0

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon and relay are available with their original images"
fi
exit "$fail"
