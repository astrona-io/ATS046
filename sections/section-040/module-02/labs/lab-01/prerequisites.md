# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl` and `jq`.
- You know the difference between `Audit` and `Enforce` for a Kyverno ClusterPolicy, what a `ValidatingAdmissionPolicy` and its binding are, and how a policy report lists results.

The lab starts a single-node kind cluster (Kubernetes 1.35), installs Kyverno 1.19.1 and creates the Starfleet workloads. The cluster pulls the Kyverno manifest and the images, so the machine needs access to the internet. Starting the lab takes several minutes because of the Kyverno installation.
