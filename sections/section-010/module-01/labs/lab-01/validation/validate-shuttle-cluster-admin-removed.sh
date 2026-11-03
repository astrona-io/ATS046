#!/usr/bin/env bash
# Check: no binding of the shuttle service account to cluster-admin remains,
# and the service account still exists (deleting it is not a fix).
set -uo pipefail

fail=0

remaining="$(kubectl get clusterrolebindings,rolebindings -A -o json | jq -r '
  .items[]
  | select(.roleRef.name == "cluster-admin")
  | select(any(.subjects[]?; .kind == "ServiceAccount" and .name == "shuttle" and .namespace == "starfleet"))
  | .kind + "/" + .metadata.name')"
if [ -n "$remaining" ]; then
  echo "FAIL: shuttle is still bound to cluster-admin by: $remaining"
  fail=1
fi

if ! kubectl -n starfleet get serviceaccount shuttle >/dev/null 2>&1; then
  echo "FAIL: the shuttle service account was deleted; remove the binding and keep the account"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle is not bound to cluster-admin and its service account still exists"
fi
exit "$fail"
