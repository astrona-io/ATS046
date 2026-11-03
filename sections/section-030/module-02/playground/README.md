# Signing And Verifying Images — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Kyverno 1.19.1 (`--allowInsecureRegistry=true`), a plain-HTTP `registry:2.8.3`
in `supply-chain`, three unsigned images in it and a `toolbox` pod with cosign
2.6.5 and Trivy 0.76.1. UNTESTED: built with static checks only. No key, no
signature, no policy. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-030-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, the toolbox and the registry, lets the node pull from it, copies three images in |
| `manifests/` | Namespaces, toolbox pod, registry Deployment and Service, node access Job |
| `docs/overview.md` | What the environment contains and ideas to try |
