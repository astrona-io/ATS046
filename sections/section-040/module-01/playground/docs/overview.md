# Overview: Automation, Findings And Control Drift (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and a Trivy toolbox, and then waits. There is no task, no `astrona submit` and no pass or fail. Scan, fix, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. There is no policy engine and no runtime detector.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `scout` (no `securityContext`), `probe` (a privileged container) and `shuttle` (hardened, but it writes `/tmp/last-run` to its root file system) |
  | `outpost` | The `drifter` client, with no `securityContext` |
  | `tools` | The `trivy` toolbox Deployment (image `ghcr.io/aquasecurity/trivy:0.76.1`, started with `tail -f /dev/null`) and the ConfigMap `trivy-exceptions`, which holds the Trivy ignore file and starts with an empty list |

## Helper

Paste this once in each new terminal. `trivy_scan` copies the live Deployments `scout`, `probe` and `shuttle` and the exception register into the toolbox pod, and then runs `trivy config` there. Any argument you pass goes to `trivy config`. The command uses `--skip-check-update`, so Trivy uses the checks built into the tool and needs no download.

```sh
trivy_scan() {
  kubectl -n tools exec deploy/trivy -- sh -c 'rm -rf /work && mkdir -p /work/live'
  for name in scout probe shuttle; do
    kubectl -n starfleet get deployment "$name" -o yaml | kubectl -n tools exec -i deploy/trivy -- sh -c "cat > /work/live/$name.yaml"
  done
  kubectl -n tools get configmap trivy-exceptions -o jsonpath='{.data.trivyignore\.yaml}' | kubectl -n tools exec -i deploy/trivy -- sh -c 'cat > /work/trivyignore.yaml'
  kubectl -n tools exec deploy/trivy -- sh -c "cd /work && trivy config --quiet --skip-check-update --ignorefile trivyignore.yaml $* live"
}
```

Use it like this: `trivy_scan --severity HIGH,CRITICAL` or `trivy_scan --format json`.

## Practice tasks

- Run `trivy_scan --severity HIGH,CRITICAL`. Write down which workload has which check ID, and predict which fields in the YAML cause each one.
- Remove `privileged: true` from `probe` with `kubectl patch`, scan again, and compare the live pod with the Deployment. Find out which of the two Trivy scanned.
- Add an entry for `KSV-0014` to the `trivy-exceptions` ConfigMap with `paths`, `statement` and `expired_at`. Scan again and find where `shuttle` shows up.
- Run `trivy_scan --format json --output /work/report.json`, then print the file with `kubectl -n tools exec deploy/trivy -- cat /work/report.json` and find the fields that name the target and the check.
- Change `scout` back by hand with `kubectl edit` after you fixed it. Scan again and note that nothing but the scan tells you about the change.
