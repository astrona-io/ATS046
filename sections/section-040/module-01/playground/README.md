# Automation, Findings And Control Drift - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
Starfleet workloads run in `starfleet` and `outpost` with deliberate
misconfigurations. A toolbox Deployment `trivy` in `tools` runs the Trivy 0.76.1
image, so the Trivy command-line tool needs no installation on your machine.
The ConfigMap `trivy-exceptions` in `tools` is the exception register and starts
empty. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, workloads with deliberate findings, the Trivy toolbox, the empty exception register |
| `docs/overview.md` | What the environment contains, the `trivy_scan` helper and ideas to try |
