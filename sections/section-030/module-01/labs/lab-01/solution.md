# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output of the tools is described in words, because file sizes, package counts and findings change with the Trivy version and database.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/labs/lab-01
```

Paste this helper once in your terminal. It runs a command inside the toolbox pod:

```sh
tb() { kubectl -n supply-chain exec toolbox -- "$@"; }
```

## Step 1: Read the deployed digest

The container runtime records the digest of the image it pulled in `status.containerStatuses[].imageID` of the pod. Read it and keep the part after the `@`:

```sh
IMAGE_ID=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')
DIGEST=${IMAGE_ID##*@}
echo "$DIGEST"
```

The command prints one line that starts with `sha256:` and has 64 hexadecimal characters.

## Step 2: Create the SBOM of that digest

Create the output folders and run `trivy image` with the `spdx-json` format against the image reference that uses the digest:

```sh
tb mkdir -p /work/sbom /work/reports
tb trivy image --format spdx-json --output /work/sbom/scout.spdx.json "ghcr.io/stefanprodan/podinfo@$DIGEST"
tb sh -c 'jq "{spdxVersion, name, packages: (.packages | length)}" /work/sbom/scout.spdx.json'
```

The first Trivy run downloads some data and can take a minute. The `jq` command prints the SPDX version, the document name and the number of packages. Run the grader:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/labs/lab-01 --keep
```

The check `sbom-for-scout` now passes. If it fails with "not an SPDX document", the `--format` value was wrong. `cyclonedx` creates a different format.

## Step 3: Scan the SBOM

Scan the SBOM file with `trivy sbom`. Trivy reads the package list from the file and looks each package up in its vulnerability database. It does not pull the image again.

```sh
tb trivy sbom --severity HIGH,CRITICAL --format json --output /work/reports/scout-sbom-scan.json /work/sbom/scout.spdx.json
tb sh -c 'jq "[.Results[]?.Vulnerabilities[]?] | length" /work/reports/scout-sbom-scan.json'
```

The second command prints the number of findings. Remember it. The check `sbom-scan-report` passes when the file is a Trivy JSON report with no `LOW`, `MEDIUM` or `UNKNOWN` finding.

## Step 4: Record the evidence

Compute each value from the cluster and the files. The decision depends on the findings count, so read it first:

```sh
SBOM_SHA=$(tb sha256sum /work/sbom/scout.spdx.json | cut -d' ' -f1)
PACKAGES=$(tb jq '.packages | length' /work/sbom/scout.spdx.json)
FINDINGS=$(tb jq '[.Results[]?.Vulnerabilities[]?] | length' /work/reports/scout-sbom-scan.json)
echo "findings: $FINDINGS"
```

When `FINDINGS` is `0`, create the record with the decision `approved`:

```sh
kubectl -n starfleet create configmap scout-release-evidence \
  --from-literal=image-digest="$DIGEST" \
  --from-literal=sbom-sha256="$SBOM_SHA" \
  --from-literal=spdx-package-count="$PACKAGES" \
  --from-literal=high-critical-count="$FINDINGS" \
  --from-literal=decision=approved
```

When `FINDINGS` is more than `0`, the release team either rejects the release or accepts the risk with an owner and an expiry date. To accept it, read a date 30 days from now in the toolbox (the `busybox` `date` in the pod accepts `@` seconds) and add the three extra keys:

```sh
EXPIRES=$(tb sh -c 'date -u -d "@$(( $(date +%s) + 2592000 ))" +%F')
kubectl -n starfleet create configmap scout-release-evidence \
  --from-literal=image-digest="$DIGEST" \
  --from-literal=sbom-sha256="$SBOM_SHA" \
  --from-literal=spdx-package-count="$PACKAGES" \
  --from-literal=high-critical-count="$FINDINGS" \
  --from-literal=decision=approved-with-exception \
  --from-literal=exception-owner=platform-team \
  --from-literal=exception-expires="$EXPIRES"
```

To reject instead, use `--from-literal=decision=rejected` and no exception keys. Run the grader a last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-030/module-01/labs/lab-01
```

All four checks pass. The check `evidence-matches-artifacts` fails when a value does not match the cluster. The common causes are the tag used in place of the digest, a hash of a different file, or a count typed by hand. The check `release-decision` fails when the decision does not follow the report, or when an exception has no owner or an expiry in the past.
