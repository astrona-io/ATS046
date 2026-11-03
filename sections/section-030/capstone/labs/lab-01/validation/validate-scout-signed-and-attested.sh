#!/usr/bin/env bash
# Check: scout carries a signature and an SBOM attestation from the learner key; probe is signed but has no SBOM attestation.
set -uo pipefail

fail=0
exhausted=0
REGISTRY_HOST="registry.supply-chain.svc.cluster.local:5000"

# tb runs a command inside the toolbox pod (cosign, Trivy, jq and helpers live there).
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }

# server_create <namespace>: sends the manifest on stdin to the API server with
# --dry-run=server, so every admission webhook runs and nothing is stored.
server_create() {
  kubectl create -n "$1" --dry-run=server -o json -f - 2>&1
}

# pod_manifest <name> <image>
pod_manifest() {
  cat <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $1
  labels:
    app: grader
spec:
  containers:
    - name: test
      image: $2
      command: ["sleep", "3600"]
YAML
}

# expect_rejected <description> <namespace> <image> [text the message must contain]
# Retries for about 45 seconds, because Kyverno needs a few seconds to register a new policy.
expect_rejected() {
  local description="$1" namespace="$2" image="$3" needle="${4:-}" tries=15 out=""
  [ "$exhausted" -eq 1 ] && tries=1
  for _ in $(seq 1 "$tries"); do
    if ! out="$(pod_manifest grader-pod "$image" | server_create "$namespace")"; then
      if [ -n "$needle" ] && ! printf '%s' "$out" | grep -q "$needle"; then
        echo "FAIL: $description was rejected, but not by the expected policy ($needle): $(printf '%s' "$out" | tail -2)"
        fail=1
      fi
      return 0
    fi
    [ "$tries" -gt 1 ] && sleep 3
  done
  exhausted=1
  echo "FAIL: $description was accepted, but it must be rejected"
  fail=1
}

# expect_accepted <description> <namespace> <image>
expect_accepted() {
  local description="$1" namespace="$2" image="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(pod_manifest grader-pod "$image" | server_create "$namespace")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description was rejected, but it must be accepted: $(printf '%s' "$out" | tail -3)"
  fail=1
}

# prepare_foreign_copy <repository> <tag> <source image> <attest yes|no>
# Copies an image into the registry and signs it (and optionally attaches an SBOM
# attestation) with a throwaway key that is NOT the learner's key.
prepare_foreign_copy() {
  tb sh -c '
    set -eu
    repo="$1"; tag="$2"; source_image="$3"; attest="$4"
    mkdir -p /tmp/grader && cd /tmp/grader
    [ -f cosign.key ] || cosign generate-key-pair >/dev/null 2>&1
    cosign copy -f --allow-insecure-registry --allow-http-registry "$source_image" "$REGISTRY/$repo:$tag" >/dev/null 2>&1
    digest="$(image-digest "$repo" "$tag")"
    cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/$repo@$digest" >/dev/null 2>&1
    if [ "$attest" = "yes" ]; then
      [ -f /tmp/grader/sbom.spdx.json ] || trivy image --quiet --format spdx-json --output /tmp/grader/sbom.spdx.json "$source_image" >/dev/null 2>&1
      cosign attest --yes --key cosign.key --type spdxjson --predicate /tmp/grader/sbom.spdx.json --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/$repo@$digest" >/dev/null 2>&1
    fi
  ' sh "$1" "$2" "$3" "$4"
}

key=/work/keys/cosign.pub
tb test -s "$key" 2>/dev/null || { echo "FAIL: $key does not exist. Generate the key pair in /work/keys"; exit 1; }
cosign_flags="--key $key --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry"
scout="$(tb image-digest starfleet/scout 6.15.0)"
probe="$(tb image-digest starfleet/probe 6.15.0)"
if [ -z "$scout" ] || [ -z "$probe" ]; then
  echo "FAIL: the registry has no starfleet/scout:6.15.0 or starfleet/probe:6.15.0"
  exit 1
fi
# shellcheck disable=SC2086
if ! tb cosign verify $cosign_flags "$REGISTRY_HOST/starfleet/scout@$scout" >/dev/null 2>&1; then
  echo "FAIL: starfleet/scout@$scout has no signature that verifies with $key"
  exit 1
fi
# shellcheck disable=SC2086
if ! tb cosign verify-attestation $cosign_flags --type spdxjson "$REGISTRY_HOST/starfleet/scout@$scout" >/dev/null 2>&1; then
  echo "FAIL: starfleet/scout@$scout has no spdxjson attestation signed with $key"
  exit 1
fi
# shellcheck disable=SC2086
if ! tb cosign verify $cosign_flags "$REGISTRY_HOST/starfleet/probe@$probe" >/dev/null 2>&1; then
  echo "FAIL: starfleet/probe@$probe must be signed too, but it has no signature that verifies"
  exit 1
fi
# shellcheck disable=SC2086
if tb cosign verify-attestation $cosign_flags --type spdxjson "$REGISTRY_HOST/starfleet/probe@$probe" >/dev/null 2>&1; then
  echo "FAIL: starfleet/probe must stay without an SBOM attestation, so the gate can be shown to block it"
  exit 1
fi
echo "PASS: scout is signed and attested; probe is signed and has no SBOM attestation"
