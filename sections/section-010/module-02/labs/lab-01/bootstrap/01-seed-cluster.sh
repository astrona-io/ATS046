#!/usr/bin/env bash
# Starting state for the kube-bench lab. Environment only: it creates the
# empty `compliance` namespace. The Job, the summary and the exceptions are
# the learner's work.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/compliance.yaml"
kubectl get namespace compliance >/dev/null
echo "[lab] Ready."
