# Overview: Kubernetes Attack Paths (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a compromised-looking `shuttle` pod and then waits. There is no task, no `astrona submit` and no pass or fail. Walk the attack path as an attacker who already runs a command in `shuttle`, then break each step, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. The default network plugin of `kind` enforces NetworkPolicy.
- The example workloads:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | `shuttle` | A `curl` pod. It is privileged, runs as root, mounts the node directory `/var/log` at `/host-logs` and keeps its service account token |
  | `starfleet` | service account `shuttle` | A `Role` and `RoleBinding` named `shuttle-secret-reader` let it get and list Secrets in `starfleet` |
  | `starfleet` | `scout`, `probe` | Backends on port 80 of their Services (container ports 9898 and 8080) |
  | `starfleet` | Secret `fleet-credentials` | The data an attacker wants |
  | `outpost` | `drifter` | A client pod of another team |

## Helpers

Paste these once in each new terminal. `in_shuttle` runs a command inside the `shuttle` pod, as the attacker would.

```sh
in_shuttle() {
  kubectl -n starfleet exec deploy/shuttle -- "$@"
}
```

Use it like this: `in_shuttle ls /var/run/secrets/kubernetes.io/serviceaccount` or `in_shuttle ls /host-logs`.

## Practice tasks

- From inside `shuttle`, read the service account token and the namespace file from the mounted directory, and describe what an attacker can do with them.
- From inside `shuttle`, call the Kubernetes API Service with the token and read the Secret `fleet-credentials`. Then remove the `Role` binding and repeat the request.
- Check what `shuttle` can see on the node through `/host-logs`, then remove the `hostPath` volume and the `privileged` flag.
- Set `automountServiceAccountToken: false` in the pod spec and confirm the token directory is gone from the new pod.
- Write a NetworkPolicy that lets `shuttle` reach only `probe` and DNS, and prove that a request to `scout` is refused.
