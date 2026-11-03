---
draft: true
exam_objectives:
  - Supply Chain Compliance
---
# Verification Decisions And Retention

The release team now holds a digest, an SBOM and a scan report for `scout`. A manager asks: is it approved? The records alone do not answer that. Someone, or something, has to compare them with a rule and say yes or no. If the answer is "no, but ship it anyway", that decision needs its own record. And months later, when a new vulnerability appears, the team needs the old records to still exist.

This part covers the decision, the exception and the retention of release evidence.

## A signature is not a decision

A signature says that the holder of a key vouched for some bytes. It does not say that the bytes are acceptable. Take a team that signs every image its pipeline builds, including a build of an old, vulnerable branch. The signature is valid for that image. A verification that checks only "is there a valid signature?" admits it.

A **verification decision** is the outcome of checking evidence against a policy. A useful policy asks several questions about one digest:

1. Is the signer an identity or key that we trust?
2. Does the SBOM or the provenance name this exact digest?
3. Is the vulnerability result acceptable under our rule?
4. Is there an exception that covers what failed, and is it still valid?

The decision is one of a small set of outcomes. Keeping the outcomes distinct matters, because a missing record and an invalid record call for different follow-up:

| Outcome | Meaning | Typical follow-up |
| --- | --- | --- |
| Approved | Every required record is present, valid and acceptable | Deploy |
| Rejected: missing evidence | A required record does not exist | Ask the producer to create it |
| Rejected: invalid evidence | A record exists but does not verify, or names another digest | Investigate, because this can indicate tampering |
| Rejected: findings | Records are valid but the result is not acceptable | Fix, or request an exception |
| Approved with exception | A documented exception covers the failure | Deploy and track the exception |

## Try it: scan the SBOM and apply a rule

The rule for this exercise is: no HIGH or CRITICAL finding. Define the helper and read the digest, then create the SBOM if it does not exist:

<!-- astrona:playground:renew -->

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
IMAGE_ID=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')
DIGEST=${IMAGE_ID##*@}
tb mkdir -p /work/sbom /work/reports
tb trivy image --format spdx-json --output /work/sbom/scout.spdx.json "ghcr.io/stefanprodan/podinfo@$DIGEST"
```

Scan the SBOM file, not the image. Trivy reads the package list from the file and looks each package up in its database:

```sh
tb trivy sbom --severity HIGH,CRITICAL --format json --output /work/reports/scout-sbom-scan.json /work/sbom/scout.spdx.json
```

Count the findings in the report:

```sh
tb sh -c 'jq "[.Results[]?.Vulnerabilities[]?] | length" /work/reports/scout-sbom-scan.json'
```

The command prints a single number. It can be zero or higher, because the database changes every day. Apply the rule: zero findings means approved. Any finding means rejected, unless an exception covers it.

## Recording the decision

A decision that lives only in someone's memory cannot be reviewed. Store it next to the digest it applies to. A ConfigMap is a simple place to try this. Compute the values from the cluster and the files:

```sh
SBOM_HASH=$(tb sha256sum /work/sbom/scout.spdx.json | cut -d' ' -f1)
PACKAGES=$(tb sh -c 'jq ".packages | length" /work/sbom/scout.spdx.json')
FINDINGS=$(tb sh -c 'jq "[.Results[]?.Vulnerabilities[]?] | length" /work/reports/scout-sbom-scan.json')
echo "$SBOM_HASH $PACKAGES $FINDINGS"
```

The last command prints a 64-character hash and two numbers. Save the record as `scout-release-evidence.yaml`. Replace each placeholder with the value you computed, and set `decision` to `approved` when the findings count is zero and `rejected` otherwise:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-release-evidence
  namespace: starfleet
data:
  image-digest: "<the digest>"
  sbom-sha256: "<the hash>"
  spdx-package-count: "<the packages>"
  high-critical-count: "<the findings>"
  decision: "approved"
```

Apply it:

```sh
kubectl apply -f scout-release-evidence.yaml
```

Then read it back:

```sh
kubectl -n starfleet get configmap scout-release-evidence -o yaml
```

The record now ties one digest to the hash of its SBOM, the size of the SBOM, the result of the scan and the decision. A reviewer can recompute the hash from the stored file and compare.

## Exceptions need an owner and an end date

Sometimes the release must go ahead despite a finding. The fix may not exist yet, or the vulnerable code path may not be reachable. An **exception** records that the risk was accepted on purpose.

A usable exception has four parts:

- **Scope.** Which digest and which finding it covers. An exception for one image must not silently cover the next build.
- **Owner.** A named team that accepted the risk and will follow up.
- **Expiry.** A date after which the exception no longer applies.
- **Reason.** Why the release proceeds and what risk remains.

For the ConfigMap above, an accepted finding changes the decision to `approved-with-exception` and adds two keys: `exception-owner` (a team name) and `exception-expires` (a date such as `2027-01-31`). A rejected release carries neither key, because nothing was accepted.

An exception without an expiry becomes permanent by neglect. Someone must check the date, and a check that runs automatically is better than a calendar reminder.

## What happens when verification fails to run

A policy has a written intent and an effective behavior. Suppose the verification service is down and the admission controller is set to allow requests when the service does not answer. For the length of the outage, every image is admitted, signed or not. The assessment should record how the control behaves when verification cannot run, and whether that matches the intent.

## Retention and later findings

Keep enough evidence to relate a deployed version to its origin and approval at the time of approval. That means the SBOM, the provenance, the signatures, the scan report with its date, and the decision record.

Three practices protect that evidence:

1. **Keep records for as long as the artifact can run.** A registry cleanup that deletes old images and their attestations can make a later investigation impossible.
2. **Protect the records.** An SBOM reveals internal dependencies and versions. Limit who can read the store, and limit who can change it.
3. **Rescan over time.** A scan that passed last month is historical evidence. When new vulnerabilities are published, scan the stored SBOMs again and find the deployments that are affected. Because every record names a digest, the match is exact.

## Common pitfalls

> [!WARNING]
> Do not equate a valid signature with approval. The signature identifies who vouched for the bytes. The decision comes from checking the evidence against a policy.

> [!WARNING]
> Do not grant an exception without an owner and an expiry date. An undated exception outlives the reason it was granted, and nobody remembers to review it.
