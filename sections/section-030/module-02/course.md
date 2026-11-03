---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Signing And Verifying Images

A cluster pulls images from a registry, and a registry accepts pushes from anyone who holds the right credentials. If an attacker pushes a different image under the tag the cluster already uses, the cluster runs it without complaint. Nothing in Kubernetes asks who made an image. This module adds that question and enforces the answer.

You will sign an image with cosign, attach an SBOM to it as an attestation, and write a Kyverno policy that refuses any pod whose image lacks a valid signature from your key. Keep one idea in mind: **a signature binds a key to a digest, and a policy decides which keys the cluster accepts.**

The module has three parts. **Digests And Key-Based Signing** creates a key pair, signs the digest of an image and verifies it. **Attestations And SBOMs** attaches a signed SBOM to the same digest and verifies it by predicate type. **The Kyverno Verification Gate** writes the admission policy that checks signatures and attestations when a pod is created.

## Learning goals

After this module you can:

- Explain why a signature must cover a digest and not a tag.
- Create a cosign key pair, sign an image and verify the signature.
- Attach an SBOM as a signed attestation and verify it by type.
- Write a Kyverno `ClusterPolicy` that refuses pods whose images are unsigned or signed by an unknown key.
- Explain what a verification gate does not check.

## Before you start

You need to know what a container image and a pod are, and how to write a Kubernetes manifest. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It has these parts:

| Where | What it is |
| --- | --- |
| Kyverno 1.19.1 | Installed and ready, started with `--allowInsecureRegistry=true` so it can reach a registry without TLS (for testing only). No policy exists. |
| registry in `supply-chain` | A plain-HTTP registry at `registry.supply-chain.svc.cluster.local:5000`. The node pulls from it. |
| images in the registry | `starfleet/scout:6.15.0` and `starfleet/probe:6.15.0` (both `podinfo`), and `outpost/drifter:2.25.0` (`go-httpbin`). All unsigned. |
| pod `toolbox` in `supply-chain` | Has cosign 2.6.5, Trivy 0.76.1, `jq` and `curl`, a working directory `/work`, and the variable `REGISTRY` with the registry address. |

The namespaces `starfleet` and `outpost` are empty. `kubectl` already points at the cluster.

Launch your playground now and keep it running while you read:

<!-- astrona:playground -->
