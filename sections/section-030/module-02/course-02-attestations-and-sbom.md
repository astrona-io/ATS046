---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Attestations And SBOMs

The scout image is signed. The platform team now wants more than "someone vouched for it". It wants the SBOM stored with the image, and it wants proof that the SBOM was made by the release team and not pasted in later. A plain signature cannot carry that, because the signed payload holds only the digest. An attestation can.

## Signature versus attestation

A **signature** says: this key vouches for this digest. The payload has no other content.

An **attestation** says: this key vouches for this claim about this digest. The claim is a document, such as an SBOM or a provenance record, and it travels inside an in-toto statement. The statement holds the subject (the image name and digest), a **predicate type** (a URI that names the kind of claim) and the **predicate** (the document). Cosign signs the statement and stores it in the registry next to the image.

An attestation gives you two things a signature does not. The claim itself is stored with the artifact, so anyone can read it. And the predicate type labels the claim, so a verifier can ask for "an SPDX SBOM signed by this key" and refuse a statement of another type.

## Predicate types

The predicate type is the label that matters to a policy. Cosign accepts a short name and fills in the URI:

| Cosign name | Predicate type URI | Content |
| --- | --- | --- |
| `spdxjson` | `https://spdx.dev/Document` | SPDX SBOM in JSON form |
| `cyclonedx` | `https://cyclonedx.org/bom` | CycloneDX SBOM |
| `slsaprovenance` | `https://slsa.dev/provenance/v0.2` | SLSA provenance, version 0.2 |
| `vuln` | `https://cosign.sigstore.dev/attestation/vuln/v1` | A vulnerability scan result |

A policy that requires `https://spdx.dev/Document` rejects an image that carries only a CycloneDX attestation, even if the same key signed it. Name the exact type you need.

## Try it: attach an SBOM as an attestation

<!-- astrona:playground:renew -->

This exercise needs a key pair in `/work/keys` and a signed scout digest. Define the helper first, then, if the playground is fresh, create both with the two commands after it. Skip those two commands when you already have both. The flag `--tlog-upload=false` skips the transparency log, and the two registry flags allow the plain-HTTP test registry.

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
tb sh -c 'mkdir -p /work/keys && cd /work/keys && cosign generate-key-pair'
tb sh -c 'cd /work/keys && cosign sign --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Create the SPDX SBOM of the scout digest. Trivy reads the image from the in-cluster registry, so it needs the flag that allows plain HTTP:

```sh
tb mkdir -p /work/sbom
tb sh -c 'trivy image --image-src remote --insecure --format spdx-json --output /work/sbom/scout.spdx.json "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Attach the file as an attestation of type `spdxjson`. Cosign builds the statement, signs it with the private key and pushes it:

```sh
tb sh -c 'cd /work/keys && cosign attest --yes --key cosign.key --tlog-upload=false --allow-insecure-registry --allow-http-registry --type spdxjson --predicate /work/sbom/scout.spdx.json "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

List the tags again:

```sh
tb sh -c 'curl -s http://$REGISTRY/v2/starfleet/scout/tags/list'
```

The list now has a second tag that starts with `sha256-` and ends with `.att`. That entry holds the attestation. The `.sig` entry holds the signature.

## Verify by type and key

Verify the attestation with the public key and the type:

```sh
tb sh -c 'cd /work/keys && cosign verify-attestation --key cosign.pub --type spdxjson --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

Cosign prints a message that it checked the claims and the signatures, and then the verified statement. The statement is encoded, so decode it with `jq` to read the subject and the predicate type. The first `jq` call picks the payload field and `base64 -d` decodes it:

```sh
tb sh -c 'cd /work/keys && cosign verify-attestation --key cosign.pub --type spdxjson --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)" 2>/dev/null | jq -r .payload | base64 -d | jq "{predicateType, subject}"'
```

The output has the predicate type `https://spdx.dev/Document` and a subject list with the image name and the same SHA-256 digest that you signed.

Now ask for a type that does not exist on this image:

```sh
tb sh -c 'cd /work/keys && cosign verify-attestation --key cosign.pub --type cyclonedx --insecure-ignore-tlog --allow-insecure-registry --allow-http-registry "$REGISTRY/starfleet/scout@$(image-digest starfleet/scout 6.15.0)"'
```

The command fails, because the image has no attestation of type `cyclonedx` that verifies. The key was right and the digest was right, and the type was missing.

## The attestation names its subject

The statement holds the digest of the image it describes. A verifier compares that digest with the digest of the image it checks. If an attacker copies an attestation from one image and attaches it to another, the subject no longer matches the image, and a correct verifier rejects it. This is why the subject digest is part of the signed statement and not just a convention.

An attestation is only as honest as its producer. If the SBOM was made by a tool that missed components, the signature still verifies. The signature protects the document from change, and it says nothing about how complete the document is.

## Common pitfalls

> [!WARNING]
> An attestation without a type check proves little. A verifier that accepts any signed statement admits an image whose only attestation is something else, such as a scan result that nobody asked for.

> [!WARNING]
> A verified SBOM is not a clean SBOM. The signature shows who produced the document and that it did not change. Whether the components are safe is a separate decision.
