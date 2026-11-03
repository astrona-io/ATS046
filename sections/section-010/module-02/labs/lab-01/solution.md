# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01
```

## Step 1: Run kube-bench as a Job

kube-bench reads files and processes of the node, so the pod needs `hostPID: true` and read-only host paths. It must run on the control-plane node, because the `master` and `etcd` checks look at the files of that node. Save this as `job-kube-bench.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench
  namespace: compliance
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app: kube-bench
    spec:
      hostPID: true
      restartPolicy: Never
      nodeSelector:
        node-role.kubernetes.io/control-plane: ""
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Exists
          effect: NoSchedule
      containers:
        - name: kube-bench
          image: docker.io/aquasec/kube-bench:v0.16.0
          command: ["kube-bench", "run", "--targets", "master,node,etcd,policies", "--benchmark", "cis-2.0", "--json"]
          volumeMounts:
            - {name: var-lib-etcd, mountPath: /var/lib/etcd, readOnly: true}
            - {name: var-lib-kubelet, mountPath: /var/lib/kubelet, readOnly: true}
            - {name: var-lib-kube-scheduler, mountPath: /var/lib/kube-scheduler, readOnly: true}
            - {name: var-lib-kube-controller-manager, mountPath: /var/lib/kube-controller-manager, readOnly: true}
            - {name: etc-systemd, mountPath: /etc/systemd, readOnly: true}
            - {name: lib-systemd, mountPath: /lib/systemd/, readOnly: true}
            - {name: srv-kubernetes, mountPath: /srv/kubernetes/, readOnly: true}
            - {name: etc-kubernetes, mountPath: /etc/kubernetes, readOnly: true}
            - {name: usr-bin, mountPath: /usr/local/mount-from-host/bin, readOnly: true}
            - {name: etc-cni-netd, mountPath: /etc/cni/net.d/, readOnly: true}
            - {name: opt-cni-bin, mountPath: /opt/cni/bin/, readOnly: true}
      volumes:
        - {name: var-lib-etcd, hostPath: {path: /var/lib/etcd}}
        - {name: var-lib-kubelet, hostPath: {path: /var/lib/kubelet}}
        - {name: var-lib-kube-scheduler, hostPath: {path: /var/lib/kube-scheduler}}
        - {name: var-lib-kube-controller-manager, hostPath: {path: /var/lib/kube-controller-manager}}
        - {name: etc-systemd, hostPath: {path: /etc/systemd}}
        - {name: lib-systemd, hostPath: {path: /lib/systemd}}
        - {name: srv-kubernetes, hostPath: {path: /srv/kubernetes}}
        - {name: etc-kubernetes, hostPath: {path: /etc/kubernetes}}
        - {name: usr-bin, hostPath: {path: /usr/bin}}
        - {name: etc-cni-netd, hostPath: {path: /etc/cni/net.d/}}
        - {name: opt-cni-bin, hostPath: {path: /opt/cni/bin/}}
```

Apply it and wait for the Job:

```sh
kubectl apply -f job-kube-bench.yaml
kubectl -n compliance wait --for=condition=complete job/kube-bench --timeout=300s
```

If the Job fails instead, read the pod log and the pod events with `kubectl -n compliance describe pod -l app=kube-bench`. Check that the log is one JSON document:

```sh
kubectl -n compliance logs job/kube-bench | sed -n '/^{/,$p' | jq -r '.Controls[] | .node_type + " " + .version + " fail=" + (.total_fail | tostring)'
```

You should see four lines, one per target, each with the version `cis-2.0` and a number of failures. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01 --keep
```

The check `kube-bench-job-completed` passes.

## Step 2: Store the summary

Build the summary from the log with `jq` and save it to a file:

```sh
kubectl -n compliance logs job/kube-bench | sed -n '/^{/,$p' | jq '[.Controls[] | {id, version, node_type, total_pass, total_fail, total_warn, total_info, failed: ([.tests[]?.results[]? | select(.status == "FAIL") | .test_number] | sort)}]' > summary.json
kubectl -n compliance create configmap kube-bench-summary --from-file=summary.json=summary.json
```

The ConfigMap now holds one object per target. Extra fields such as `id` and `version` are allowed. Grade it: the check `kube-bench-summary-matches` passes.

## Step 3: Record the accepted failures

List the failed checks of the control plane target with their text:

```sh
kubectl -n compliance logs job/kube-bench | sed -n '/^{/,$p' | jq -r '.Controls[] | select(.node_type == "master") | .tests[]?.results[]? | select(.status == "FAIL") | .test_number + " " + .test_desc'
```

Pick one identifier from the list, for example the first one. Save this as `kube-bench-exceptions.yaml`, and replace `1.2.1` with the identifier you picked:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-bench-exceptions
  namespace: compliance
data:
  "1.2.1": "Accepted for this assessment: the fix changes the API server static pod, which the namespace owner does not control."
```

Apply it:

```sh
kubectl apply -f kube-bench-exceptions.yaml
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01
```

All three checks pass. Clean up with `astrona destroy ats-046-lab-010-02`.
