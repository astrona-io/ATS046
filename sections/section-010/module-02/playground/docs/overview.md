# Overview: Auditing A Cluster Against The CIS Kubernetes Benchmark (Playground)

This is a **playground**, not a lab. It starts a fresh cluster and waits. There is no task, no `astrona submit` and no pass or fail. Run kube-bench, read the findings, change the way you run it, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. The one node is the control plane and runs the workloads. `kubectl` is already pointed at it, as the cluster administrator. You need `jq` on your machine to read the JSON report.
- The image `docker.io/aquasec/kube-bench:v0.16.0` is already loaded into the node, so a Job that uses it starts without a download.
- An empty namespace `compliance`, with no Pod Security labels, for the kube-bench Job and your records.
- The example workloads:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | `scout`, `probe`, `shuttle` | The example application |
  | `outpost` | `drifter` | A client that belongs to another team |

- kube-bench itself is not installed. You run it as a Job, which is how you run it on a real cluster.

## Helpers

Paste these once in each new terminal. `bench_log` prints the kube-bench log of the Job `kube-bench` in `compliance` from the first line that starts with `{`. `failed_checks` prints the identifier of every check with the status `FAIL` in a JSON report that comes from standard input.

```sh
bench_log() {
  kubectl -n compliance logs job/kube-bench | sed -n '/^{/,$p'
}
failed_checks() {
  jq -r '.Controls[] | .node_type as $target | .tests[]?.results[]? | select(.status == "FAIL") | $target + " " + .test_number'
}
```

Use them like this: `bench_log | failed_checks`.

## Practice tasks

- Run kube-bench for one target only, for example `--targets master`, and compare the number of checks with a run for `master,node`. Delete the Job between runs.
- Run it with `--check 1.2.1,1.2.2` and read what the report contains. Then run it with `--skip 1.2.1` and find how a skipped check appears.
- Print the `remediation` text of one failed check from the JSON report and decide who can apply it on a managed cluster.
- Run it with `--targets policies` and count the statuses. Explain why every result has the same status.
- Run it twice without any change and compare the failed identifiers of both runs. Decide what a difference would mean.
