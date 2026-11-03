# Question

Solve this question on: `terminal`

The release team must record the evidence for the `scout` image before the platform team approves it. The cluster runs `scout`, `probe` and `shuttle` in `starfleet` and `drifter` in `outpost`. A pod named `toolbox` in the namespace `supply-chain` has `cosign` and `trivy` installed and a working directory `/work`. Run the tools with `kubectl -n supply-chain exec toolbox -- ...`. Do not change the running workloads.

1. Read the digest of the image that the `scout` pod runs in `starfleet`. Use the digest, not the tag `6.15.0`.

2. In the toolbox, create a Software Bill of Materials (SBOM) of that exact image in SPDX JSON format. Save it as `/work/sbom/scout.spdx.json`.

3. In the toolbox, scan the SBOM file (not the image) with Trivy. Keep only `HIGH` and `CRITICAL` findings and save the JSON report as `/work/reports/scout-sbom-scan.json`.

4. Create the ConfigMap `scout-release-evidence` in `starfleet` with these keys. Take every value from the cluster or from the files, not from memory.
   - `image-digest`: the digest of the image the `scout` pod runs, in the form `sha256:...`.
   - `sbom-sha256`: the SHA-256 hash of the SBOM file.
   - `spdx-package-count`: the number of packages listed in the SBOM.
   - `high-critical-count`: the number of findings in the scan report.
   - `decision`: `approved` when the report has no finding. When it has findings, `rejected`, or `approved-with-exception` when the release team accepts the risk.

5. If you choose `approved-with-exception`, add the keys `exception-owner` (a team name) and `exception-expires` (a date in the form `2026-12-31` that is after today). A `rejected` decision must not carry exception keys.

The Trivy vulnerability database changes every day, so the report may or may not contain findings. Your decision must follow the report you made.
