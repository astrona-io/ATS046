# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. Tool output is described in words, because it contains digests and keys that differ on every run.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/labs/lab-01
```

Paste this helper once in your terminal. It runs a command inside the toolbox pod:

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

`astrona submit` right after the start shows two checks that already pass. `other-registries-unaffected` passes because no policy exists. It stays your guard: it fails if your policy matches images from other registries.

## Step 1: Generate the key pair and sign the digest

`cosign generate-key-pair` writes `cosign.key` (encrypted with the password) and `cosign.pub` in the current directory. Run it in `/work/keys`:

```sh
tb sh -c 'mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair'
tb sh -c 'ls /work/keys'
```

The listing shows `cosign.key` and `cosign.pub`. Next, read the digest the registry stores for the tag `6.15.0` with the helper `image-digest`, and sign that digest:

```sh
tb image-digest starfleet/scout 6.15.0
```

The command prints one line that starts with `sha256:`. Sign the digest. The three flags at the end are needed for this registry: `--tlog-upload=false` because there is no transparency log, and `--allow-insecure-registry` with `--allow-http-registry` because the registry has no TLS.

```sh
tb sh -c 'cd /work/keys && cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Cosign stores the signature in the registry as an extra tag in the same repository. Verify it the way Kyverno will:

```sh
tb sh -c 'cd /work/keys && cosign verify --key cosign.pub --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Cosign prints a short message that it checked the signature against the public key, then a JSON document with the image identity. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/labs/lab-01 --keep
```

The check `scout-signature-verifies` now passes.

## Step 2: Write the policy

Print the public key, because you paste it into the policy:

```sh
tb cat /work/keys/cosign.pub
```

Save this as `clusterpolicy-require-signed-images.yaml`. Replace the three lines between `BEGIN` and `END` with your key and keep the indentation:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-signed-images
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
```

Apply it:

```sh
kubectl apply -f clusterpolicy-require-signed-images.yaml
```

Then check that the policy is ready:

```sh
kubectl get clusterpolicy require-signed-images
```

The `READY` column shows `True` after a few seconds. The `imageReferences` pattern limits the rule to the lab registry, so images from `ghcr.io` are not checked. `ignoreTlog: true` tells Kyverno not to look for a transparency log entry, because the signature was made with `--tlog-upload=false`.

## Step 3: Prove the gate

Try an unsigned image with a server-side dry run, so Kyverno runs and nothing is stored:

```sh
kubectl -n outpost run unsigned-test --image=registry.supply-chain.svc.cluster.local:5000/outpost/drifter:2.25.0 --dry-run=server
```

Kubernetes refuses the request. The message names the policy `require-signed-images` and says the image verification failed. Now try the signed image, by tag and a public image:

```sh
kubectl -n starfleet run signed-test --image=registry.supply-chain.svc.cluster.local:5000/starfleet/scout:6.15.0 --dry-run=server
kubectl -n starfleet run public-test --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

Both print `pod/... created (server dry run)`. Run the grader without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-02/labs/lab-01
```

All five checks pass. The check `foreign-key-rejected` fails when the policy only needs any signature or when it has the wrong public key. The check `other-registries-unaffected` fails when `imageReferences` is `*`.
