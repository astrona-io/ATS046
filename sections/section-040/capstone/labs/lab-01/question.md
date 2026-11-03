# Question

Solve this question on: `terminal`

The compliance team runs a continuous loop on the `starfleet` namespace: scan, fix, enforce, repair drift and record exceptions. Run one full turn of the loop. `kubectl` points at the cluster as the cluster administrator. A Trivy toolbox pod runs in the `tools` namespace, and Kyverno 1.19.1 is installed with no policy.

Paste this helper once. It copies the live Deployments `scout`, `probe` and `shuttle` and the exception register into the toolbox pod and runs `trivy config` there. Any argument goes to `trivy config`.

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

1. **Scan and fix.** The `probe` Deployment runs a privileged container (check `KSV-0017`). Remove the privileged setting. Do not delete or scale down the Deployment. Its pod must run again without the setting.

2. **Repair drift.** The ConfigMap `approved-manifests` in `tools` holds the approved manifest of `scout` in the key `scout.yaml`. The live `scout` Deployment was edited by hand and no longer matches it. Bring the live Deployment back to the approved state. Do not change the image.

3. **Enforce privileged containers.** Create a Kyverno ClusterPolicy that rejects a privileged Pod, and so a privileged Deployment, in `starfleet`. The policy must not apply to `outpost`: a privileged pod there must still be accepted.

4. **Prevent the drift from returning.** Create a ValidatingAdmissionPolicy and a binding that deny a Deployment with `hostNetwork` set to true in `starfleet`. The rule must not apply to `outpost`.

5. **Record an exception.** The `shuttle` Deployment writes the file `/tmp/last-run` on its root file system, so it cannot run with a read-only root file system (check `KSV-0014`). Do not change `shuttle`. Record an exception in the ConfigMap `trivy-exceptions` in `tools`, key `trivyignore.yaml`. The register must hold exactly one entry under `misconfigurations`, with these fields:
   - `id`: `KSV-0014`
   - `paths`: a list that names the `shuttle` manifest as Trivy prints it (the helper scans the directory `live`)
   - `statement`: one line that gives the reason, the owner and a compensating control
   - `expired_at`: a date in the form `yyyy-mm-dd` that is in the future and not more than 90 days from today

`shuttle` must still get an answer from the `scout` and `probe` Services at the end. Do not change the `outpost` namespace.
