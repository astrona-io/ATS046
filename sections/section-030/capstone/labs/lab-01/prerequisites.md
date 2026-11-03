# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl`. The lab start downloads the Kyverno 1.19.1 release manifest, cosign 2.6.5 and Trivy 0.76.1 from GitHub, and copies images from `ghcr.io` and Docker Hub into the in-cluster registry, so the machine needs internet access.
- You can sign an image with cosign, attach an attestation, and write a Kyverno policy that verifies images.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno, a registry and a toolbox pod. The start takes several minutes. The commands are in the README of this folder.
