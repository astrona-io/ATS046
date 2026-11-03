# Question

Solve this question on: `terminal`

The platform team runs a container registry inside the cluster at `registry.supply-chain.svc.cluster.local:5000`. It speaks plain HTTP and holds the images `starfleet/scout:6.15.0`, `starfleet/probe:6.15.0` and `outpost/drifter:2.25.0`. Kyverno 1.19.1 is installed with the flag `--allowInsecureRegistry=true`, but no policy exists. A pod named `toolbox` in the namespace `supply-chain` has `cosign` and `trivy` installed. The environment variable `REGISTRY` in the toolbox holds the registry address. Do not change the registry, Kyverno or the images.

1. In the toolbox, generate a cosign key pair in `/work/keys`. The private key password is already in the environment variable `COSIGN_PASSWORD`.

2. Sign the image `starfleet/scout:6.15.0` by its digest. The registry has no TLS and there is no transparency log, so the signature must not be uploaded to one.

3. Create a Kyverno `ClusterPolicy` named `require-signed-images`. A pod that uses an image from the lab registry must carry a signature that verifies with the public key `/work/keys/cosign.pub`. The policy must refuse the pod, not only record it. A signature from any other key must not pass. Images from other registries, such as `ghcr.io/stefanprodan/podinfo:6.15.0`, must keep working.

`kubectl` already points at the cluster. Run the tools with `kubectl -n supply-chain exec toolbox -- ...`. Kyverno takes a few seconds to start using a new policy, so run a check again if it still shows the old result. Applying a `kyverno.io/v1` ClusterPolicy prints a deprecation warning. You can ignore it.
