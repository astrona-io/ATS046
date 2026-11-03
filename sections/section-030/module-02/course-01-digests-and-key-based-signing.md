---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Digests And Key-Based Signing

The release team has pushed `starfleet/scout:6.15.0` to the cluster registry. The Deployment will refer to it by that tag. Anyone with push rights can upload another image under the same tag, and the next pod that starts will run it. The team wants a check that says: this image was approved by us. A signature is that check, and this part shows how it works down to what is stored in the registry.

## What a signature covers

A digital signature is made with a private key and checked with the matching public key. If the signed data changes by one bit, the check fails.

Cosign, the signing tool of the Sigstore project, does not sign the image layers. It signs a small JSON document called the **payload**. The payload holds the image digest (the SHA-256 hash of the image manifest) and a type label. Cosign signs the payload bytes with the private key and stores the signature in the registry.

The consequence is that **a signature vouches for one digest**. Suppose `scout:6.15.0` points at digest A today and you sign it. If someone moves the tag to digest B tomorrow, the signature for A is still valid and still attached to A. Digest B has no signature at all. A verifier that resolves the tag finds digest B and looks for a signature on B, so it finds none and fails. That is the behaviour you want, and it only works because the signature is tied to the digest.

## Where the signature lives

Cosign stores the signature as another object in the same registry and under the same image name. It uses a tag that is computed from the digest: the text `sha256-` followed by the hex digest, then `.sig`. The image and its signature are two separate entries that share a name. Because the signature is just another registry object, copying the image alone does not copy the signature, and deleting the signature tag removes the proof while leaving the image in place.

## Try it: create a key pair and sign

Define a helper that runs a command in the toolbox:

<!-- astrona:playground:renew -->

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

Generate a cosign key pair. The command reads the private key password from the variable `COSIGN_PASSWORD`, which the toolbox sets to a lab-only value:

```sh
tb sh -c 'mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair'
```

The folder `/work/keys` now holds `cosign.key` (the encrypted private key) and `cosign.pub` (the public key). In a real system the private key lives in a key management service or a hardware token, and never in a pod.

Read the digest that the registry stores for the tag. The toolbox has a helper called `image-digest` that takes the image name and the tag:

```sh
tb image-digest starfleet/scout 6.15.0
```

The command prints one line that starts with `sha256:`. Now sign that digest. The registry has no TLS and no transparency log, so the command needs three extra flags:

```sh
tb sh -c 'cd /work/keys && cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

The flag `--tlog-upload=false` skips the public transparency log (Rekor), which a closed test cluster cannot reach. `--allow-insecure-registry` and `--allow-http-registry` allow the plain-HTTP registry. Never use these flags against a production registry.

Look at what the registry stores for the name:

```sh
tb sh -c 'curl -s http://$REGISTRY/v2/starfleet/scout/tags/list'
```

The response is a JSON document with the image name and a list of tags. It contains `6.15.0` and a second tag that starts with `sha256-` and ends with `.sig`. That second entry is the signature.

## Verify with the public key

Verification needs only the public key and the digest. Run it the way a verifier would:

```sh
tb sh -c 'cd /work/keys && cosign verify --key cosign.pub --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Cosign prints a short message that it checked the claims and the signature against the supplied public key, and then a JSON document with the image reference and the payload. The flag `--insecure-ignore-tlog` matches the signing step: there is no log entry to look for.

Now see what a wrong key does. Make a second key pair and verify with its public key:

```sh
tb sh -c 'mkdir -p /work/other && cd /work/other && cosign generate-key-pair && cosign verify --key cosign.pub --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

The second `cosign verify` fails with an error that says the signature does not match. The image is the same and the signature is intact, but the second public key did not make it. A verifier accepts the keys it is told to accept and no others.

## Keys, trust and what a signature does not say

A signature answers "did the holder of this key vouch for this digest?". The cluster still has to decide whether it trusts that key. A policy that accepts any valid signature accepts the attacker's own signature too, since an attacker can sign their image with their own key. A real policy names the public keys, or in keyless signing the identities, that it trusts.

A signature also does not say the image is free of defects, that its dependencies are safe, or that the holder of the key was careful. It says who vouched, and nothing more.

Finally, a private key that leaks lets an attacker sign anything the team would sign. Protect the key, rotate it on a schedule, and have a plan to stop trusting a key that leaked.

## Common pitfalls

> [!WARNING]
> Always give cosign the digest when you sign. A tag can move between the lookup and the signature, and a signature attached to the wrong digest protects nothing.

> [!WARNING]
> A valid signature is not a trusted signature. A verification that accepts any key, or a policy that lists the wrong public key, admits images signed by an attacker.
