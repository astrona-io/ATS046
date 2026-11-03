# Overview: Compliance Scope And Control Evidence (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and three deliberate control failures, and then waits. There is no task, no `astrona submit` and no pass or fail. Collect evidence, change the cluster, collect the evidence again, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. You need `jq` on your machine for the evidence commands.
- The example workloads, each on a service account with its own name:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | `scout`, `probe`, `shuttle` | The example application |
  | `outpost` | `drifter` | A client that belongs to another team |
  | `starfleet` | ClusterRoleBinding `shuttle-admin` | Gives the `shuttle` service account the `cluster-admin` role, on purpose |
  | `starfleet` | Deployment `probe` | Its container runs with `privileged: true`, on purpose |

- Every pod mounts a service account token, because Kubernetes does that by default.
- No evidence record exists yet.

## Helpers

Paste these once in each new terminal. `cluster_admin_bindings` lists every binding to `cluster-admin` with its subjects. `token_mounts` lists each pod of a namespace with the number of service account token volumes it has. `privileged_pods` lists the pods of a namespace that have a privileged container.

```sh
cluster_admin_bindings() {
  kubectl get clusterrolebindings,rolebindings -A -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .kind + " " + .metadata.name + " -> " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
}
token_mounts() {
  kubectl -n "$1" get pods -o json | jq -r '.items[] | .metadata.name + " token-volumes=" + ([.spec.volumes[]? | select(.name | startswith("kube-api-access"))] | length | tostring)'
}
privileged_pods() {
  kubectl -n "$1" get pods -o json | jq -r '.items[] | select(any(.spec.containers[]; .securityContext.privileged == true)) | .metadata.name'
}
```

Use them like this: `cluster_admin_bindings`, `token_mounts starfleet`, `privileged_pods starfleet`.

## Practice tasks

- Run `privileged_pods kube-system` and explain why the result is not a failure of the `starfleet` assessment. Name the scope you would write down for each result.
- Find every service account in the cluster that can read Secrets in `starfleet`. Use `kubectl auth can-i --list --as=...` for the identities you know about.
- Set `automountServiceAccountToken: false` on the `scout` pod template, wait for the rollout, and run `token_mounts starfleet` again. Write down what changed and what did not.
- Remove the `shuttle-admin` binding and check that the `shuttle` pod is still running. Decide what evidence proves the control now passes.
- Write an evidence record as a ConfigMap with the scope, the Kubernetes version from `kubectl version`, the time of observation and one line per control. Change the cluster again and decide whether the record is still true.
