# Question

Solve this question on: `terminal`

A scan of the `starfleet` namespace with Trivy reports configuration findings. The security team accepts the namespace only when the following three findings are closed in the cluster. A Trivy toolbox pod runs in the `tools` namespace, and `kubectl` already points at the cluster as the cluster administrator.

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

1. The `probe` Deployment runs a privileged container (check `KSV-0017`). Remove the privileged setting. Do not delete or scale down the Deployment. Its pod must run again without the setting, and `shuttle` must still get an answer from the `probe` Service.

2. The `scout` Deployment has no `securityContext`. Change it so every `scout` pod runs with `runAsNonRoot: true`, a numeric `runAsUser` that is not `0`, `seccompProfile.type: RuntimeDefault`, `allowPrivilegeEscalation: false` and `capabilities.drop: ["ALL"]`. Every replica must be available, and `shuttle` must still get an answer from the `scout` Service.

3. The `shuttle` Deployment writes the file `/tmp/last-run` on its root file system, so it cannot run with a read-only root file system (check `KSV-0014`). Do not change `shuttle`. Record an exception for the finding in the ConfigMap `trivy-exceptions` in the namespace `tools`, in the key `trivyignore.yaml`. The register must hold exactly one entry under `misconfigurations`, with these fields:
   - `id`: `KSV-0014`
   - `paths`: a list that names the `shuttle` manifest as Trivy prints it (the helper scans the directory `live`)
   - `statement`: one line that gives the reason, the owner and a compensating control
   - `expired_at`: a date in the form `yyyy-mm-dd` that is in the future and not more than 90 days from today

Do not change the `outpost` namespace. Other findings on other workloads are out of scope.
