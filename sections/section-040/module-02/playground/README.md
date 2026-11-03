# Policy Enforcement And Runtime Detection - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED. Built and checked with static checks only (`astrona validate`, `bash -n`, YAML parsing). It has not been started.

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Kyverno 1.19.1, installed from its release manifest by `bootstrap/prepare.sh`
(no Helm). The Starfleet workloads run in `starfleet` and `outpost`. On
purpose, `probe` runs a privileged container and no Deployment has an `owner`
label. No ClusterPolicy and no ValidatingAdmissionPolicy exist. Falco is not
installed: it needs kernel access that kind does not give reliably, so the
course reads Falco rules as text. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-040-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the config
path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, waits for its webhooks, then applies the workloads |
| `manifests/starfleet.yaml` | Namespaces, service accounts and workloads, with the deliberate gaps |
| `docs/overview.md` | What the environment contains, helpers and ideas to try |
