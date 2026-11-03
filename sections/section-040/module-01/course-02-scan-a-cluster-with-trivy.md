---
draft: true
exam_objectives:
  - Automation and Tooling
---
# Scan A Cluster With Trivy

A finding is only useful when you can reproduce it and read it. This part runs a real configuration scan on the live Deployments of the playground, and reads each piece of the result: the target, the check ID, the severity and the lines that caused it. The scan is the first step of every compliance loop, because it turns a vague worry ("some pods are too privileged") into a list of named objects.

## What Trivy does

**Trivy** is an open-source scanner from Aqua Security. It has several modes. The mode used here is `trivy config`, which is a **misconfiguration scanner**: it reads configuration files, decides what type each file is (Kubernetes, Dockerfile, Terraform, Helm), and runs a set of **checks** on them. A check is a rule written in the Rego policy language. Each check has an ID, a title, a severity and a recommended action.

Kubernetes checks have IDs that start with `KSV`, for example `KSV-0017` (privileged container), `KSV-0001` (privilege escalation allowed), `KSV-0012` (container may run as root), `KSV-0014` (root file system is not read-only) and `KSV-0118` (the default security context is used). Older Trivy releases and older documents write the same IDs as `AVD-KSV-0017` or `KSV017`. The IDs are an alias of each other.

Trivy needs the check rules to run. By default it downloads the latest rule bundle from a container registry. The flag `--skip-check-update` tells it to skip that download and use the rules that were built into the tool. The playground uses that flag, so the result depends only on the Trivy version and not on the moment of the scan.

## The playground helper

Trivy does not read a cluster directly in `trivy config`; it reads files. The playground therefore exports the live Deployments to files inside the toolbox pod, and scans the directory. The pod in `tools` runs the Trivy image and does nothing else. Paste this helper once. It exports `scout`, `probe` and `shuttle` as YAML, copies the exception register into the pod, and runs `trivy config` with any arguments you add.

<!-- astrona:playground:renew -->

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

The helper has three jobs. `kubectl get ... -o yaml` asks the API server for the stored object, so the scan sees defaults and fields that controllers added. The `-i` flag on `kubectl exec` passes the YAML through standard input into a file. The last line runs Trivy in the directory `/work` and scans the folder `live`, so the file names in the report are `live/scout.yaml`, `live/probe.yaml` and `live/shuttle.yaml`.

## Run the first scan

Run the scan and limit the output to the severities that need a decision first.

```sh
trivy_scan --severity HIGH,CRITICAL
```

Trivy prints one block for each file that has findings. The block header names the file and its type, for example `live/probe.yaml (kubernetes)`, and a line with the number of tests and how many failed. Each failure then shows the severity, the check ID, a title, a short description and a code excerpt with line numbers. The exact numbers depend on the Trivy version, and Trivy shows only the findings that match the severity filter.

Read the `probe` block first. The check `KSV-0017` points at the lines of the container `securityContext` where `privileged: true` is set. The excerpt is the evidence: it shows the object, the field and the value. The same block can list `KSV-0014` and `KSV-0118`, because `probe` also has a writable root file system and an incomplete security context.

## Findings are scoped to a target

The scan read the Deployment, not the pods. This matters for two reasons. A Deployment is a template, and Kubernetes creates pods from it. A finding on the template describes what the next pod will have. A pod that was created before a template change keeps its old settings until it is replaced.

To see the difference, list the pods of `probe` and ask the API server for the container security context of the running pod:

```sh
kubectl -n starfleet get pods -l app=probe -o jsonpath='{.items[*].spec.containers[*].securityContext}{"\n"}'
```

The command prints the JSON of the `securityContext` field of each container. It shows `"privileged":true`, which is the effective behavior that the scan reports. After a fix, this same command is the proof that the running pod changed.

## Reading the severity filter and other output

The `--severity` flag accepts a list of `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH` and `CRITICAL`. Without the flag Trivy prints every severity, which is a long report for three small Deployments. The flag `--format json` prints a machine-readable report, which is the form to store as evidence. A short comparison:

```sh
trivy_scan --severity CRITICAL
trivy_scan --format json --severity HIGH,CRITICAL
```

The first command prints nothing for a block when no finding matches. The second prints one JSON document. The document has a `Results` list with one entry for each file, and each entry has a `Target` field with the file name and a `Misconfigurations` list. Each misconfiguration has the fields `ID`, `Title`, `Severity`, `Message`, `Resolution` and a `CauseMetadata` object with the lines of the cause. These are the fields an automated pipeline reads.

## Other ways to give Trivy a target

The same checks run on other targets. In a delivery pipeline, `trivy config` reads the manifest files of a repository before they reach any cluster. That scan finds a problem earlier and costs less to fix, but it cannot see what a webhook or a controller changes later. The command `trivy k8s` connects to a running cluster with a kubeconfig and scans the resources it finds, which gives wider coverage but needs read access to the cluster.

Each target answers a different question. A repository scan asks whether the approved source is clean. A live scan asks whether the cluster is clean. When both exist, a difference between the two results is itself a signal: it means the cluster no longer matches its source, which is called control drift.

## What the scan cannot tell you

The scan reports declared settings. It does not know the answers to these questions. Is a `NetworkPolicy` enforced by the network plugin? Does an admission policy reject the pod before it starts? Does the container do something that no manifest field describes? A clean `trivy config` result answers none of them.

It also depends on what you gave it. The helper scans three Deployments. A Pod that someone created by hand in `starfleet`, a Job, or a workload in `outpost` is not in the report, and the report does not say so. A scan that is meant as evidence needs a stated scope: which namespaces, which kinds, which time.

This part ran a scan, read a finding and compared the declared setting with the running pod.

## Common pitfalls

> [!WARNING]
> - **Reading only the table.** The excerpt and the check ID are the evidence. A count of findings does not say which object or field is wrong.
> - **Scanning the template and claiming the pod.** A Deployment scan describes the template. Read the running pod to see the effective settings.
> - **Forgetting the scope.** A scan lists only the files it received. A workload you did not export is not covered.
> - **Mixing rule versions.** `--skip-check-update` pins the rules to the tool version. A scan without it can use a newer rule bundle and give different results.
> - **Filtering and forgetting.** `--severity HIGH,CRITICAL` hides the `MEDIUM` and `LOW` findings. Say which filter you used when you report a result.
