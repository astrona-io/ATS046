#!/usr/bin/env bash
# Starting state for the admission policy lab. Environment only: it installs
# Kyverno, waits for its webhooks, creates the workloads (probe runs a
# privileged container) and then the Audit-mode ClusterPolicy. It creates no
# ValidatingAdmissionPolicy.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done
kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s

# The admission controller registers its webhook configurations after it starts.
for name in kyverno-policy-validating-webhook-cfg kyverno-resource-validating-webhook-cfg kyverno-resource-mutating-webhook-cfg; do
  for i in $(seq 1 60); do
    if kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration 2>/dev/null | grep -q "$name"; then
      break
    fi
    sleep 2
  done
done

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for name in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

# Create the policy after the workloads, so probe is already running when the
# policy starts to audit.
kubectl apply -f "$DIR/manifests/audit-policy.yaml" 2>&1 | grep -v '^Warning: kyverno.io/v1 ClusterPolicy is deprecated' || true
kubectl wait --for=condition=Ready clusterpolicy/disallow-privileged-containers --timeout=120s
echo "[lab] Ready."
