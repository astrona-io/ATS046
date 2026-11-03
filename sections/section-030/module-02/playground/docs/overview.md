# Overview: Signing And Verifying Images (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno, a container registry and a toolbox pod, and then waits. There is no task, no `astrona submit` and no pass or fail. Sign images, write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Kyverno 1.19.1** with its webhooks ready and the admission, background, reports and cleanup controllers started with `--allowInsecureRegistry=true`. This flag lets Kyverno talk to a registry without TLS and is only for testing. No ClusterPolicy exists yet.
- A plain-HTTP registry (`registry:2.8.3`) in the namespace `supply-chain`. Its address is `registry.supply-chain.svc.cluster.local:5000`. The kind node is set up to pull images from it. It holds three unsigned images:

  | Image | Content |
  | --- | --- |
  | `starfleet/scout:6.15.0` | `podinfo` 6.15.0 |
  | `starfleet/probe:6.15.0` | `podinfo` 6.15.0 (the same digest, a different repository) |
  | `outpost/drifter:2.25.0` | `go-httpbin` 2.25.0 |

- A pod named `toolbox` in `supply-chain` with **cosign 2.6.5**, **Trivy 0.76.1**, `jq`, `curl` and a working directory `/work`. The environment variable `REGISTRY` holds the registry address and `COSIGN_PASSWORD` holds a lab-only password. The helper `image-digest <repository> <tag>` prints a tag's digest.
- The namespaces `starfleet` and `outpost`, with no workload.

## Helper

Paste this once in each new terminal. It runs a command inside the toolbox pod:

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

For a command that needs a shell (pipes, `cd`, `$REGISTRY`), write `tb sh -c '...'`. Cosign needs `--allow-insecure-registry --allow-http-registry` against this registry, and `--tlog-upload=false` when it signs, because there is no transparency log.

## Practice tasks

- Generate a key pair, sign `starfleet/scout` by digest and run `cosign verify`. Then list the tags of the image name with `curl` against the registry and find the signature tag.
- Copy `starfleet/probe` to a new tag with `cosign copy`, and check which tags carry the signature of the scout digest and which do not.
- Attach an SPDX SBOM to `scout` with `cosign attest --type spdxjson` and read it back with `cosign verify-attestation`.
- Write a Kyverno policy that requires a signature for the registry and look at what `mutateDigest` does to a pod that uses a tag.
- Start a real pod from the signed image (`kubectl -n starfleet run ...`) and check that it runs.
