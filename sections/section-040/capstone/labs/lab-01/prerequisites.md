# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl` and `jq`.
- You know how to scan live Deployments with Trivy inside a toolbox pod, how a Kyverno ClusterPolicy and a ValidatingAdmissionPolicy with a binding reject a request, and what an exception needs (reason, scope, owner, expiry).

The lab starts a single-node kind cluster (Kubernetes 1.35), installs Kyverno 1.19.1 and creates the Starfleet workloads and a Trivy toolbox pod. You do not install Trivy on your own machine. The cluster pulls the Kyverno manifest and the images, so the machine needs access to the internet. Starting the lab takes several minutes.
