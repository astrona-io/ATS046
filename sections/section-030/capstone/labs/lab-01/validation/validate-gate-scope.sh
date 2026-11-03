#!/usr/bin/env bash
# Check: the gate does not block outpost or images from other registries.
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

expect_accepted "an unsigned image in outpost, outside the gate" outpost "$REGISTRY_HOST/outpost/drifter:2.25.0"
expect_accepted "an image from ghcr.io in starfleet" starfleet "ghcr.io/stefanprodan/podinfo:6.15.0"
if [ "$fail" -eq 0 ]; then
  echo "PASS: the gate applies to starfleet and to the lab registry only"
fi
exit "$fail"
