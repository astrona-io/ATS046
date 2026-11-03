# Supply Chain Assurance Evidence — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
Starfleet workloads and a `toolbox` pod in `supply-chain` with cosign 2.6.5 and
Trivy 0.76.1, installed by `bootstrap/prepare.sh`. UNTESTED: built with static
checks only. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-030-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Applies the workloads, starts the toolbox pod, installs cosign and Trivy |
| `manifests/starfleet.yaml` | Namespaces, service accounts and workloads |
| `manifests/toolbox.yaml` | The `supply-chain` namespace and the toolbox pod |
| `docs/overview.md` | What the environment contains and ideas to try |
