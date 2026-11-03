# Question

Solve this question on: `terminal`

The `shuttle` pod in `starfleet` is the foothold of an attack path. An attacker who runs one command inside it can read the service account token of `shuttle`, use the token to read the Secret `fleet-credentials`, reach every service in the namespace, and use the privileged container and the mounted node directory to reach the node. Break the path in four places. Do not delete or scale down any workload, do not delete the service account `shuttle`, and do not delete the Secret.

1. RBAC. The service account `shuttle` can read Secrets in `starfleet` through a `Role` and a `RoleBinding`. `shuttle` never calls the Kubernetes API. Remove the access, so the service account has no binding left and cannot read Secrets, list pods or create pods.

2. Token. Kubernetes mounts the service account token into every pod by default. The running `shuttle` pods must not have a service account token volume or the directory `/var/run/secrets/kubernetes.io/serviceaccount`.

3. securityContext. The `shuttle` container is privileged, runs as root and mounts the node directory `/var/log` as a `hostPath` volume. Change the Deployment so the running pods are not privileged, have no `hostPath` volume, cannot gain more privileges, drop all Linux capabilities, run as a non-root user and are Ready.

4. NetworkPolicy. A compromised `shuttle` can call every pod. `shuttle` must reach only the Service `probe` (container port 8080) and DNS. A request to the Service `scout` and to the `scout` pod address must be refused.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as`.
