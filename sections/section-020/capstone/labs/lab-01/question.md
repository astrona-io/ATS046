# Question

Solve this question on: `terminal`

A threat model of the Starfleet application in `starfleet` lists these threats. `scout` and `shuttle` do not call the Kubernetes API. `shuttle` is the only pod that may call `probe`. `caller` (a pod in `starfleet`) and `drifter` (a pod in `outpost`) must not. Do not delete or scale down any workload, any service account or the Secret `fleet-credentials`.

1. Elevation of privilege through RBAC. The service account `scout` is bound to `cluster-admin` by a `ClusterRoleBinding`. Remove the grant. `scout` and `shuttle` must have no rights to read Secrets, create pods or change the cluster.

2. Spoofing of a service account. Both Deployments keep a service account token in their pods. Neither workload uses it. The running `scout` and `shuttle` pods must have no token volume and no service account directory.

3. Elevation of privilege through the container. The `scout` container is privileged, runs as root and mounts the node directory `/etc` as a `hostPath` volume. Change the Deployment so the running pods are not privileged, have no `hostPath` volume, cannot gain more privileges, drop all Linux capabilities, run as a non-root user and are Ready.

4. Information disclosure on the network. Only `shuttle` may reach `probe`. `shuttle` must keep reaching it. Use a NetworkPolicy.

5. Residual risk. Create the ConfigMap `residual-risk` in `starfleet` with the keys `spoofing`, `information-disclosure` and `elevation-of-privilege`. Each value is one sentence of at least 40 characters that says what is still possible after your mitigation for that threat.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as`.
