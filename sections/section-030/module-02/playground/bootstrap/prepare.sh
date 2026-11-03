#!/usr/bin/env bash
# Environment prep for the Signing And Verifying Images playground (ats-046-playground-030-02).
# Environment only: no task state, no grading. No ClusterPolicy exists afterwards.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

KYVERNO_VERSION="v1.19.1"
COSIGN_VERSION="v2.6.5"
TRIVY_VERSION="0.76.1"
REGISTRY_HOST="registry.supply-chain.svc.cluster.local:5000"

# Installs cosign and Trivy into the toolbox pod and adds the image-digest helper.
install_toolbox() {
  kubectl apply -f "$DIR/manifests/toolbox.yaml"
  kubectl -n supply-chain wait --for=condition=Ready pod/toolbox --timeout=180s
  kubectl -n supply-chain exec toolbox -- sh -c '
    set -eu
    apk add --no-cache curl jq ca-certificates >/dev/null
    case "$(uname -m)" in
      x86_64)  cosign_arch=amd64; trivy_arch=64bit ;;
      aarch64) cosign_arch=arm64; trivy_arch=ARM64 ;;
      *) echo "unsupported architecture $(uname -m)" >&2; exit 1 ;;
    esac
    curl -fsSL -o /usr/local/bin/cosign "https://github.com/sigstore/cosign/releases/download/'"${COSIGN_VERSION}"'/cosign-linux-${cosign_arch}"
    chmod +x /usr/local/bin/cosign
    curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v'"${TRIVY_VERSION}"'/trivy_'"${TRIVY_VERSION}"'_Linux-${trivy_arch}.tar.gz" | tar -xz -C /usr/local/bin trivy
    cosign version >/dev/null
    trivy --version >/dev/null
  '
  # image-digest <repository> <tag> prints the digest the registry stores for a tag.
  kubectl -n supply-chain exec -i toolbox -- sh -c 'cat > /usr/local/bin/image-digest && chmod +x /usr/local/bin/image-digest' <<'SCRIPT'
#!/bin/sh
curl -sI \
  -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' \
  "http://${REGISTRY}/v2/$1/manifests/$2" | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}'
SCRIPT
}

# Installs Kyverno from its release manifest with --allowInsecureRegistry=true,
# because the lab registry speaks plain HTTP.
install_kyverno() {
  echo "Installing Kyverno ${KYVERNO_VERSION}..."
  curl -fsSL "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml" \
    | sed 's/--allowInsecureRegistry=false/--allowInsecureRegistry=true/' \
    | kubectl create -f -
  for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
    kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
  done
  kubectl wait --for=condition=Established crd/clusterpolicies.kyverno.io --timeout=120s
  for name in kyverno-policy-validating-webhook-cfg kyverno-resource-validating-webhook-cfg kyverno-resource-mutating-webhook-cfg; do
    for _ in $(seq 1 60); do
      if kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration 2>/dev/null | grep -q "$name"; then
        break
      fi
      sleep 2
    done
  done
}

# Starts the registry, lets the node pull from it, and copies three images in.
setup_registry() {
  kubectl apply -f "$DIR/manifests/registry.yaml"
  kubectl -n supply-chain rollout status deployment/registry --timeout=180s
  kubectl apply -f "$DIR/manifests/node-registry-access.yaml"
  kubectl -n supply-chain wait --for=condition=complete job/node-registry-access --timeout=180s
  # scout and probe hold the podinfo image; drifter holds go-httpbin.
  kubectl -n supply-chain exec toolbox -- sh -c '
    set -eu
    copy_image() {
      cosign copy --allow-insecure-registry --allow-http-registry "$1" "$REGISTRY/$2"
    }
    copy_image ghcr.io/stefanprodan/podinfo:6.15.0 starfleet/scout:6.15.0
    copy_image ghcr.io/stefanprodan/podinfo:6.15.0 starfleet/probe:6.15.0
    copy_image mccutchen/go-httpbin:2.25.0 outpost/drifter:2.25.0
  '
}

kubectl apply -f "$DIR/manifests/namespaces.yaml"
install_kyverno
install_toolbox
setup_registry
echo "[env] Ready: Kyverno, registry at ${REGISTRY_HOST}, cosign and Trivy in pod supply-chain/toolbox."
