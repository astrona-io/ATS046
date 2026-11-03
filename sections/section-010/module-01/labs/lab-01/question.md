# Question

Solve this question on: `terminal`

The `starfleet` namespace is the scope of a compliance check against three controls of the CIS Kubernetes Benchmark policies section. A first review found one failure for each control. Fix all three, do not delete or scale down any workload, and then record the evidence.

1. Control 5.1.1, cluster-admin is only used where required. The service account `shuttle` in `starfleet` is bound to `cluster-admin`. The `shuttle` pod never calls the Kubernetes API. Remove the grant and keep the service account.

2. Control 5.1.6, service account tokens are mounted only where necessary. The `scout` and `probe` pods do not call the Kubernetes API. Their running pods must no longer have a service account token volume.

3. Control 5.2.2, minimize the admission of privileged containers. No pod in `starfleet` may have a privileged container. The `probe` Deployment must keep running with its image.

4. Record the evidence in a ConfigMap `control-evidence` in `starfleet` with these keys:
   - `scope`: the namespace and workloads you assessed, naming `starfleet`.
   - `kubernetes-version`: the server version of this cluster, as `kubectl version` reports it.
   - `observed-at`: the time of your last check in UTC, in the form `2026-11-03T10:15:00Z`.
   - `5.1.1`, `5.1.6` and `5.2.2`: one line each, starting with `PASS` and saying what you observed.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as`.
