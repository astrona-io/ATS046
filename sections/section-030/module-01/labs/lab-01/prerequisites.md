# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`. The lab start downloads cosign 2.6.5 and Trivy 0.76.1 from GitHub into the toolbox pod, and Trivy downloads its vulnerability database when it first scans, so the machine needs internet access.
- You know what an image digest is, and you have read what an SBOM, provenance and a signature each prove.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads and the toolbox pod. The start takes a few minutes. The commands are in the README of this folder.
