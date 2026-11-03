---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Demonstrating What Was Built And Deployed

The platform team will approve `scout` only if the artifact meets defined origin and maintenance requirements. The release team could answer with a spreadsheet row that says "scout, reviewed, scanned, approved". A week later someone deploys a rebuilt `scout` under the same name, and nothing in the row has changed. The row proves nothing about the content that actually runs.

Supply chain compliance is the discipline of closing that gap. It asks you to show, with records that other people can check, how a piece of software got from a source change to a running pod. This part follows one release through its records and finds the one value that ties them together.

## The three kinds of record

A release path produces records in three places.

**Source records** describe the change. A reviewed pull request, a signed commit and a recorded revision identifier (a commit hash) show who proposed the change, who approved it and which exact text was approved.

**Build records** describe the transformation. They name the build service, the instructions it ran, the inputs it fetched (base image, dependencies) and the time. A build record answers the question "how was this made?".

**Artifact records** describe the result. For a container image the artifact is the image itself, and its identity is the digest. Artifact records include the list of components inside (an SBOM), the findings of vulnerability scans, and signatures over the image.

Each record covers a different property. A source review does not tell you what the build fetched from the internet. A clean scan does not tell you who built the image. A release is well supported when the records form a chain from the reviewed revision to the running artifact.

## The digest anchors the chain

An image has two ways to be named. A **tag** such as `6.15.0` is a label that the registry owner can move to a different image at any time. A **digest** such as `sha256:...` is a hash of the image manifest. The same digest always means the same bytes, and a changed image has a different digest.

Take two images that both carry the tag `6.15.0` on different days. If the release record says "scout:6.15.0 approved", it covers whichever image the tag pointed at when someone wrote the record. The record never mentions the second image, but the tag now names it. If the record says "sha256 of the approved manifest", the second image simply has no record, and a check finds that out.

For this reason every record in the chain should name the digest, not the tag. The tag stays useful for humans. The digest is what a program compares.

## Try it: read the digest of a running pod

Your playground runs `scout` from the tag `6.15.0`. First see what the Deployment asks for.

<!-- astrona:playground:renew -->

Print the image the Deployment is configured with:

```sh
kubectl -n starfleet get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}'
```

The command prints the tag reference `ghcr.io/stefanprodan/podinfo:6.15.0`. This is the request, and a tag can point somewhere else tomorrow. Now ask the pod what it actually runs:

```sh
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

The kubelet (the agent on each node) reports the `imageID`. It is the image reference with the digest the container runtime resolved when it pulled the image. The value ends with `@sha256:` and 64 hexadecimal characters. That digest is the identity you attach every record to.

Keep the digest in a shell variable. The expression `${IMAGE_ID##*@}` removes everything up to the last `@`:

```sh
IMAGE_ID=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')
DIGEST=${IMAGE_ID##*@}
echo "$DIGEST"
```

The last command prints one line that starts with `sha256:`.

## Evidence across the release path

Several kinds of evidence can describe one digest.

| Record | What it can show | What it cannot show |
| --- | --- | --- |
| Source review | Which revision a person approved | What the build fetched or produced |
| Build record | Which service and inputs made the artifact | Whether the build service was honest |
| Provenance | Origin and build facts in a standard form | That the source was free of defects |
| Signature | That an identity vouched for these bytes | That the bytes are safe |
| SBOM | Which components are inside | How those components behave |
| Vulnerability finding | Known issues on the day of the scan | Issues found later |

Read the right-hand column twice. Each record has a limit, and a good review states the limit next to the claim.

## Who produced the record

A record is only as reliable as its producer. A compromised build service can emit a clean-looking provenance for a malicious artifact. A scanner that runs inside the same pipeline step it judges can be told to say "no findings". An attestation format does not fix this. It carries a claim in a standard shape, but it cannot prove the claim is true.

So the team protects the identities that produce evidence: the accounts that merge source, the build service, the keys that sign, and the storage that keeps records. The more independent the producer is from the thing it vouches for, the more the record is worth.

## Frameworks and specific guarantees

Two frameworks appear in most supply chain conversations.

Supply-chain Levels for Software Artifacts (SLSA, pronounced "salsa") defines tracks and levels that describe how well a build process resists tampering and how well it records its own work. The NIST Secure Software Development Framework (SSDF) lists practices for developing software securely, from preparing the organisation to responding to reports of vulnerabilities.

Both describe **processes and assurance**. Neither promises that the finished software has no defect. A project that reaches a build level tells you something about its build process and nothing about the quality of its code.

When someone says "we are SLSA compliant", ask three questions. Which track and which level? Which version of the specification? Where is the record that shows it for this artifact? A framework name in a release note is weaker than a traceable record of the build environment and its controls. A familiar issuer and a passed level do not imply properties that nobody claimed.

## A reviewable release record

A useful release record lists:

1. The source revision.
2. The build identity (the service and its job).
3. The artifact digest.
4. The attestations attached to that digest and who signed them.
5. The outcome of verification.
6. The deployment target.
7. Any exception, with its owner and expiry date.

Each item points at another record or at a stored file. A reviewer can follow every pointer. Compare this with a dashboard of several green status indicators, which tells the reviewer that checks ran but not whether they were about the same artifact.

## Common pitfalls

> [!WARNING]
> Do not approve a tag. An approval written against `scout:6.15.0` covers whatever the tag names on the day someone reads it. Record the digest, and compare the digest of what runs with the digest that was approved.

> [!WARNING]
> An attestation format is not proof. A standard shape around a claim made by an untrusted producer is still an untrusted claim. Check who produced it and which artifact it names.
