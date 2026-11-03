# Auditing A Cluster Against The CIS Kubernetes Benchmark — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading
- **Status:** built untested (never booted by the author)

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with an
empty `compliance` namespace and the Starfleet workloads. The kube-bench image
`docker.io/aquasec/kube-bench:v0.16.0` is preloaded into the node, so the
reader runs kube-bench as a Job. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name`), not the
config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images including kube-bench, starting manifests) |
| `manifests/compliance.yaml` | The `compliance` namespace |
| `manifests/starfleet.yaml` | Namespaces, service accounts and the Starfleet workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
