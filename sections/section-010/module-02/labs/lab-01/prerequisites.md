# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know how to write a Kubernetes Job and how to read its log with `kubectl logs`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with an empty `compliance` namespace. The kube-bench image `docker.io/aquasec/kube-bench:v0.16.0` is already loaded into the node.
