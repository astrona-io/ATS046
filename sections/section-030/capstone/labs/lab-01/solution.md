# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. Tool output is described in words, because digests and keys differ on every run.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01
```

Paste this helper once. It runs a command inside the toolbox pod:

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

`gate-scope` already passes right after the start because no policy exists. It stays your guard against a policy that is too broad.

## Step 1: Key pair, signatures and the SBOM attestation

Generate the key pair and sign both images by digest:

```sh
tb sh -c 'mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair'
tb sh -c 'cd /work/keys && for r in scout probe; do cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/$r@$(image-digest starfleet/$r 6.15.0)"; done'
```

Generate the SPDX SBOM for scout by digest, then attach it as an attestation. The `--type spdxjson` flag sets the predicate type that the policy will match:

```sh
tb sh -c 'mkdir -p /work/sbom && cd /work/keys && trivy image --format spdx-json --output /work/sbom/scout.spdx.json --image-src remote --insecure "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
tb sh -c 'cd /work/keys && cosign attest --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry --type spdxjson --predicate /work/sbom/scout.spdx.json "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Check the attestation the way the policy will:

```sh
tb sh -c 'cd /work/keys && cosign verify-attestation --key cosign.pub --type spdxjson --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Cosign prints a message that it checked the claims and the signature, then the attestation payload. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The check `scout-signed-and-attested` passes.

## Step 2: The release gate

Print the public key and paste it twice into the policy, once for each rule:

```sh
tb cat /work/keys/cosign.pub
```

Save this as `clusterpolicy-release-gate.yaml`. Replace `<your key lines>` with the key lines, keep the indentation:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: release-gate
spec:
  webhookConfiguration:
    failurePolicy: Fail
    timeoutSeconds: 30
  background: false
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      verifyImages:
        - imageReferences:
            - "registry.supply-chain.svc.cluster.local:5000/*"
          failureAction: Enforce
          mutateDigest: true
          verifyDigest: true
          required: true
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      <your key lines>
                      -----END PUBLIC KEY-----
                    rekor:
                      ignoreTlog: true
                      url: https://rekor.sigstore.dev
                    ctlog:
                      ignoreSCT: true
    - name: require-sbom-attestation
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      verifyImages:
        - imageReferences:
            - "registry.supply-chain.svc.cluster.local:5000/*"
          failureAction: Enforce
          attestations:
            - type: https://spdx.dev/Document
              attestors:
                - count: 1
                  entries:
                    - keys:
                        publicKeys: |-
                          -----BEGIN PUBLIC KEY-----
                          <your key lines>
                          -----END PUBLIC KEY-----
                        rekor:
                          ignoreTlog: true
                          url: https://rekor.sigstore.dev
                        ctlog:
                          ignoreSCT: true
```

There are two rules because one `verifyImages` entry verifies signatures or attestations, not both. Apply the policy:

```sh
kubectl apply -f clusterpolicy-release-gate.yaml
```

Then check that the policy is ready:

```sh
kubectl get clusterpolicy release-gate
```

The `READY` column shows `True` after a few seconds.

## Step 3: Prove the gate

Probe has a signature but no SBOM, so the gate must refuse it. Scout has both, so it must pass:

```sh
kubectl -n starfleet run probe-test --image=registry.supply-chain.svc.cluster.local:5000/starfleet/probe:6.15.0 --dry-run=server
kubectl -n starfleet run scout-test --image=registry.supply-chain.svc.cluster.local:5000/starfleet/scout:6.15.0 --dry-run=server
```

The first request is refused with a message that names `release-gate` and the failed attestation check. The second prints `pod/scout-test created (server dry run)`. Run the grader without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/capstone/labs/lab-01
```

All five checks pass. `gate-rejects-incomplete-releases` fails if the policy checks only the signature. `attestation-key-enforced` fails if the attestation rule has no attestors, because then any attestation passes. `gate-scope` fails if the rules match other namespaces or `*` images.
