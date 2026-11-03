# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`.
- You know what a Trivy misconfiguration finding is (check ID, severity, target), what a `securityContext` does, and what an exception needs (reason, scope, owner, expiry).

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads and a Trivy toolbox pod. You do not install Trivy on your own machine. The cluster pulls the images, so the machine needs access to the internet.
