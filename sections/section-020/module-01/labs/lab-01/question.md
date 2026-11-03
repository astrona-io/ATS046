# Question

Solve this question on: `terminal`

The `starfleet` namespace runs a small application: `scout` and `probe` are backends, `shuttle` and `caller` are clients that run `curl`, and the `drifter` client belongs to another team in `outpost`. A STRIDE review of the data-flow diagram found three threats. Turn each threat into a concrete mitigation. Do not delete or scale down any workload, and do not delete the ConfigMap `scout-config` or the Secret `fleet-credentials`.

1. Elevation of privilege. The service account `scout` is bound to the built-in `edit` ClusterRole in `starfleet`. The `scout` application only has to read the ConfigMap `scout-config`. Remove the broad grant, keep the service account, and give it a `Role` and `RoleBinding` that allow only that read. `scout` must not read Secrets, change Deployments, create or delete pods, or act in another namespace.

2. Information disclosure. Every pod in the cluster can call the Service `probe`. Only the `shuttle` pods may reach it. A pod in `starfleet` that is not `shuttle` (the `caller` pod) and the `drifter` pod in `outpost` must be refused. `shuttle` must keep reaching `probe`.

3. Elevation of privilege. The `probe` container is privileged and runs as root. Change its `securityContext` so the running pod is not privileged, cannot gain more privileges, drops all Linux capabilities, runs as a non-root user and is Ready.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as`.
