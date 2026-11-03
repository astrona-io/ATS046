#!/usr/bin/env bash
# Check: shuttle keeps a writable root file system (the finding is accepted, not
# hidden by a change that breaks the workload) and is running.
set -uo pipefail

ro="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || true)"
if [ "$ro" = "true" ]; then
  echo "FAIL: shuttle sets readOnlyRootFilesystem: true, but it must write /tmp/last-run. Record an exception instead."
  exit 1
fi

desired="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.replicas}' 2>/dev/null)"
available="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.status.availableReplicas}' 2>/dev/null)"
if [ -z "$desired" ] || [ "${available:-0}" != "$desired" ]; then
  echo "FAIL: shuttle has ${available:-0} of ${desired:-?} replicas available"
  exit 1
fi

wrote="$(kubectl -n starfleet exec deploy/shuttle -- sh -c 'test -s /tmp/last-run && echo yes' 2>/dev/null || true)"
if [ "$wrote" != "yes" ]; then
  echo "FAIL: shuttle has not written /tmp/last-run (wait 30 seconds after a restart and run the check again)"
  exit 1
fi

echo "PASS: shuttle still writes its root file system and runs"
