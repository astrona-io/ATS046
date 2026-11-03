#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n supply-chain exec toolbox -- sh -c '
  set -eu
  mkdir -p /work/keys && cd /work/keys
  cosign generate-key-pair >/dev/null
  digest="$(image-digest starfleet/scout 6.15.0)"
  cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$digest"
'

# Put the public key into the policy, indented for the block scalar.
key_file="$(mktemp)"
kubectl -n supply-chain exec toolbox -- cat /work/keys/cosign.pub | sed 's/^/                      /' > "$key_file"
sed -e '/__COSIGN_PUBLIC_KEY__/{' -e "r $key_file" -e 'd' -e '}' "$DIR/solution.yaml" \
  | kubectl apply -f - 2>&1 | grep -v '^Warning: kyverno.io/v1 ClusterPolicy is deprecated' || true
rm -f "$key_file"
echo "[solution] Applied."
