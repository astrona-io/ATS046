# Structured Threat Modelling - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-046-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading
- **Status:** UNTESTED (built untested; validated statically only)

Starting state: scout is bound to the edit ClusterRole, probe is privileged and runs as root, and probe accepts traffic from every pod. kind's default network plugin (kindnet) enforces NetworkPolicy. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-046-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-046-playground-020-01`), not the config path. `astrona submit` and `astrona test` do not apply: there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/workloads.yaml` | Namespaces, service accounts and the Starfleet workloads |
| `manifests/access.yaml` | The access starting state |
| `docs/overview.md` | What the environment contains and ideas to try |
