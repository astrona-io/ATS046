# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know how to run kube-bench as a Job, how to read its JSON report, and how to check RBAC, token mounts, privileged containers and Pod Security labels with `kubectl`.

The lab starts a single-node kind cluster (Kubernetes 1.35). The kube-bench image `docker.io/aquasec/kube-bench:v0.16.0` is already loaded into the node.
