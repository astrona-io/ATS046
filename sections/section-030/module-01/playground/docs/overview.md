# Overview: Supply Chain Assurance Evidence (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and a toolbox pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Generate SBOMs, scan them, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The Starfleet workloads. `scout`, `probe` and `shuttle` run in `starfleet`. `drifter` runs in `outpost`. `scout` runs the `podinfo` image 6.15.0, `probe` runs `go-httpbin` 2.25.0, and `shuttle` and `drifter` run a `curl` image.
- A pod named `toolbox` in the namespace `supply-chain`. It has **cosign 2.6.5** and **Trivy 0.76.1** installed, `jq`, `curl`, and an empty working directory `/work`. The cluster has no registry, no Kyverno and no policy in this playground.

The toolbox needs internet access. Trivy downloads its vulnerability database the first time you scan an SBOM or an image.

## Helper

Paste this once in each new terminal. It runs a command inside the toolbox pod:

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

Use it like this: `tb trivy --version`. For a command that needs a shell (pipes, redirects), write `tb sh -c '...'`.

## Practice tasks

- Read the image digest that each of the three `starfleet` pods runs from `status.containerStatuses[].imageID`. Compare it with the tag in the Deployment.
- Create an SPDX JSON SBOM and a CycloneDX SBOM of the same `podinfo` digest. Compare the package counts and the top-level fields with `jq`.
- Scan the SBOM with `trivy sbom` once with no filter and once with `--severity HIGH,CRITICAL`. Count the findings in each report.
- Create the SBOM of the `go-httpbin` image used by `probe` and find out which of its packages are Go modules.
- Write a short evidence record for `probe` as a ConfigMap: digest, SBOM hash and decision.
