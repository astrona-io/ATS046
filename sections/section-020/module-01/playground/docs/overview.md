# Overview: Structured Threat Modelling (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a small application that has several threats on purpose, and then waits. There is no task, no `astrona submit` and no pass or fail. Draw the data flows, find the threats, apply mitigations, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. The default network plugin of `kind` enforces NetworkPolicy.
- The example workloads:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | `scout` (port 80 on its Service) | A backend that runs podinfo. Its service account is bound to the `edit` ClusterRole |
  | `starfleet` | `probe` (port 80 on its Service, container port 8080) | A backend that runs go-httpbin. Its container is privileged and runs as root |
  | `starfleet` | `shuttle`, `caller` | Client pods that run `curl` |
  | `outpost` | `drifter` | A client pod of another team that runs `curl` |
  | `starfleet` | ConfigMap `scout-config`, Secret `fleet-credentials` | Data in the namespace |

## Helpers

Paste these once in each new terminal. `http_code` sends a request from a client pod and prints only the HTTP status (`000` means the connection failed). `can_sa` checks one verb for a service account in `starfleet`.

```sh
http_code() {
  kubectl -n "$1" exec "deploy/$2" -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 "$3"
}
can_sa() {
  kubectl auth can-i "$2" "$3" -n starfleet --as="system:serviceaccount:starfleet:$1"
}
```

Use them like this: `http_code starfleet shuttle http://probe.starfleet.svc/get` or `can_sa scout get secrets`.

## Practice tasks

- Draw the data flows on paper: who calls whom, and where the trust boundaries are (the namespace edge, the Service, the node). Then list one STRIDE threat per element.
- Find out what the `scout` service account can do with `kubectl auth can-i --list`, then replace its broad grant with a `Role` for one ConfigMap.
- Prove with `http_code` that `caller` and `drifter` reach `probe`, write a NetworkPolicy, and prove that they no longer do.
- Remove `privileged` from `probe`, then try `runAsNonRoot: true` without a numeric `runAsUser` and read the pod event that explains why the pod does not start.
- For each mitigation, write one sentence that says what remains possible. That sentence is the residual risk.
