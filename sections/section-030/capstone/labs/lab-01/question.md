# Question

Solve this question on: `terminal`

The Starfleet release team wants a release gate in front of the namespace `starfleet`. A pod there may use an image from the in-cluster registry `registry.supply-chain.svc.cluster.local:5000` only when the image is signed with the team key and carries an SBOM (software bill of materials) attestation made with the same key. The registry speaks plain HTTP and holds `starfleet/scout:6.15.0`, `starfleet/probe:6.15.0` and `outpost/drifter:2.25.0`. Kyverno 1.19.1 runs with `--allowInsecureRegistry=true` and has no policy. A pod named `toolbox` in the namespace `supply-chain` has `cosign` and `trivy`; the environment variable `REGISTRY` holds the registry address. Do not change the registry, Kyverno or the images.

1. In the toolbox, generate a cosign key pair in `/work/keys`. The password is in `COSIGN_PASSWORD`.

2. Sign `starfleet/scout:6.15.0` and `starfleet/probe:6.15.0` by digest. There is no transparency log, so do not upload to one.

3. Generate an SPDX SBOM for the scout image with Trivy. Attach it to the scout digest as an attestation of type `spdxjson`, signed with your key. Do not attach an SBOM to probe.

4. Create a Kyverno `ClusterPolicy` named `release-gate`. For pods in the namespace `starfleet` that use images from the lab registry, it must refuse the pod unless the image has a valid signature from `/work/keys/cosign.pub` and a valid SPDX attestation signed by the same key. The policy must not touch other namespaces or images from other registries.

`kubectl` already points at the cluster. Run the tools with `kubectl -n supply-chain exec toolbox -- ...`. Kyverno takes a few seconds to start using a new policy, so run a check again if it still shows the old result. You can ignore the deprecation warning for `kyverno.io/v1`.
