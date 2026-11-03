#!/usr/bin/env bash
# Check: the hand-made drift on scout is repaired. Neither the Deployment
# template nor a running pod uses the host network, scout still runs the
# approved image with one replica, and the Deployment is available.
set -uo pipefail

dep="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null)"
if [ -z "$dep" ]; then
  echo "FAIL: the Deployment scout does not exist in starfleet. Repair it, do not delete it."
  exit 1
fi

if [ "$(printf '%s' "$dep" | jq '.spec.template.spec.hostNetwork == true')" = "true" ]; then
  echo "FAIL: the scout Deployment template still sets hostNetwork: true"
  exit 1
fi

image="$(printf '%s' "$dep" | jq -r '.spec.template.spec.containers[0].image')"
if [ "$image" != "ghcr.io/stefanprodan/podinfo:6.15.0" ]; then
  echo "FAIL: scout runs the image '${image}', the approved manifest uses ghcr.io/stefanprodan/podinfo:6.15.0"
  exit 1
fi

pods="$(kubectl -n starfleet get pods -l app=scout -o json 2>/dev/null)"
live="$(printf '%s' "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null)] | length')"
if [ "$live" -lt 1 ]; then
  echo "FAIL: no running scout pod exists"
  exit 1
fi
hostnet="$(printf '%s' "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp == null and .spec.hostNetwork == true)] | length')"
if [ "$hostnet" != "0" ]; then
  echo "FAIL: a scout pod still uses the host network. Wait for the rollout to finish."
  exit 1
fi

desired="$(printf '%s' "$dep" | jq '.spec.replicas')"
available="$(printf '%s' "$dep" | jq '.status.availableReplicas // 0')"
if [ "$available" != "$desired" ]; then
  echo "FAIL: scout has ${available} of ${desired} replicas available"
  exit 1
fi

echo "PASS: scout matches the approved manifest and no pod uses the host network"
