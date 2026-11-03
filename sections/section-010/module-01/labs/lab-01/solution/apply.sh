#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl delete clusterrolebinding shuttle-admin

# scout and probe do not call the Kubernetes API: stop mounting the token.
for name in scout probe; do
  kubectl -n starfleet patch deployment "$name" --type=merge \
    -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
done
# probe must not run privileged.
kubectl -n starfleet patch deployment probe --type=json \
  -p '[{"op":"remove","path":"/spec/template/spec/containers/0/securityContext/privileged"}]'

for name in scout probe; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done

version="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"
observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sed -e "s/KUBERNETES_VERSION/${version}/" -e "s/OBSERVED_AT/${observed}/" "$DIR/solution.yaml" | kubectl apply -f -
echo "[solution] Applied."
