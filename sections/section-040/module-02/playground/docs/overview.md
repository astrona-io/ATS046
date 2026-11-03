# Overview: Policy Enforcement And Runtime Detection (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno and the example workloads, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` already points at it, as the cluster administrator. Kyverno 1.19.1 runs in the `kyverno` namespace. ValidatingAdmissionPolicy is built into the API server.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | `scout`, `probe` and `shuttle`. `probe` runs a privileged container on purpose. No Deployment has an `owner` label |
  | `outpost` | The `drifter` client |

- No ClusterPolicy and no ValidatingAdmissionPolicy exist. Falco is not installed. The reading about Falco uses rules as text, and you cannot run them here.

## Helpers

Paste these once in each new terminal. `try_create` sends a manifest file to the API server as a server-side dry run, so every admission check runs and nothing is stored. `failed_results` lists every failed result in the Kyverno policy reports of a namespace.

```sh
try_create() {
  kubectl create --dry-run=server -f "$1"
}
failed_results() {
  kubectl -n "$1" get policyreport -o json | jq -r '.items[] | .scope as $s | .results[]? | select(.result=="fail") | [$s.kind,$s.name,.policy,.rule] | @tsv'
}
```

Use them like this: `try_create pod-privileged-test.yaml` and `failed_results starfleet`.

## Practice tasks

- Write a Kyverno ClusterPolicy in `Audit` mode that matches pods in `starfleet` and checks that no container is privileged. Run `failed_results starfleet` and find the Deployment that fails.
- Change the same policy to `Enforce`. Try to create a privileged pod, and read the rejection message. Check that `probe` keeps running.
- Write a ValidatingAdmissionPolicy that requires the label `owner` on Deployments, and bind it with `Warn` first. Create a Deployment without the label and note where the warning appears. Change the binding to `Deny`.
- Scope the binding with a `namespaceSelector` so it covers `starfleet` and not `outpost`. Prove the scope with a dry run in each namespace.
- Read the Falco rule in the course page again and write down, for a shell started with `kubectl exec`, which fields of the event the condition uses.
