#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n supply-chain exec toolbox -- sh -c '
  set -eu
  mkdir -p /work/keys /work/sbom && cd /work/keys
  cosign generate-key-pair >/dev/null
  flags="--yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry"
  scout="$(image-digest starfleet/scout 6.15.0)"
  probe="$(image-digest starfleet/probe 6.15.0)"
  trivy image --format spdx-json --output /work/sbom/podinfo.spdx.json ghcr.io/stefanprodan/podinfo@${scout}
  cosign sign $flags "$REGISTRY/starfleet/scout@$scout"
  cosign sign $flags "$REGISTRY/starfleet/probe@$probe"
  cosign attest $flags --type spdxjson --predicate /work/sbom/podinfo.spdx.json "$REGISTRY/starfleet/scout@$scout"
'

# Put the public key into both rules, indented for their block scalars.
key_file="$(mktemp)"
key_file_attest="$(mktemp)"
kubectl -n supply-chain exec toolbox -- cat /work/keys/cosign.pub | sed 's/^/                      /' > "$key_file"
sed 's/^ \{22\}/                          /' "$key_file" > "$key_file_attest"
sed -e '/__COSIGN_PUBLIC_KEY_ATTEST__/{' -e "r $key_file_attest" -e 'd' -e '}' \
    -e '/__COSIGN_PUBLIC_KEY__/{' -e "r $key_file" -e 'd' -e '}' "$DIR/solution.yaml" \
  | kubectl apply -f - 2>&1 | grep -v '^Warning: kyverno.io/v1 ClusterPolicy is deprecated' || true
rm -f "$key_file" "$key_file_attest"
echo "[solution] Applied."
