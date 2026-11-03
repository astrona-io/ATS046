# Compliance Scope And Control Evidence — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
Starfleet workloads (`scout`, `probe`, `shuttle` in `starfleet`, `drifter` in
`outpost`) and three deliberate control failures: the `shuttle` service
account is bound to `cluster-admin`, the `probe` container is privileged, and
every pod mounts its service account token. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, service accounts and the Starfleet workloads (`probe` is privileged) |
| `manifests/controls.yaml` | The `shuttle-admin` ClusterRoleBinding to `cluster-admin` |
| `docs/overview.md` | What the environment contains and ideas to try |
