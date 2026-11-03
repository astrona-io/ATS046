# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without running it, so the text describes what you should see instead of printing output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes: `workloads-available`.

## Step 1: Run kube-bench in audit

The Job must not run in `orbit`: after step 5 that namespace rejects pods with host paths. Save this as `job-kube-bench.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench
  namespace: audit
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
          command: ["kube-bench", "run", "--targets", "master", "--benchmark", "cis-2.0", "--json"]
          volumeMounts:
            - {name: var-lib-kubelet, mountPath: /var/lib/kubelet, readOnly: true}
            - {name: var-lib-kube-scheduler, mountPath: /var/lib/kube-scheduler, readOnly: true}
            - {name: var-lib-kube-controller-manager, mountPath: /var/lib/kube-controller-manager, readOnly: true}
            - {name: etc-systemd, mountPath: /etc/systemd, readOnly: true}
            - {name: lib-systemd, mountPath: /lib/systemd/, readOnly: true}
            - {name: srv-kubernetes, mountPath: /srv/kubernetes/, readOnly: true}
            - {name: etc-kubernetes, mountPath: /etc/kubernetes, readOnly: true}
            - {name: usr-bin, mountPath: /usr/local/mount-from-host/bin, readOnly: true}
      volumes:
        - {name: var-lib-kubelet, hostPath: {path: /var/lib/kubelet}}
        - {name: var-lib-kube-scheduler, hostPath: {path: /var/lib/kube-scheduler}}
        - {name: var-lib-kube-controller-manager, hostPath: {path: /var/lib/kube-controller-manager}}
        - {name: etc-systemd, hostPath: {path: /etc/systemd}}
        - {name: lib-systemd, hostPath: {path: /lib/systemd}}
        - {name: srv-kubernetes, hostPath: {path: /srv/kubernetes}}
        - {name: etc-kubernetes, hostPath: {path: /etc/kubernetes}}
        - {name: usr-bin, hostPath: {path: /usr/bin}}
```

Apply it and wait:

```sh
kubectl apply -f job-kube-bench.yaml
kubectl -n audit wait --for=condition=complete job/kube-bench --timeout=300s
```

Read the totals of the control plane target:

```sh
kubectl -n audit logs job/kube-bench | sed -n '/^{/,$p' | jq -r '.Controls[] | .node_type + " " + .version + " pass=" + (.total_pass | tostring) + " fail=" + (.total_fail | tostring)'
```

You should see one line for `master` with the version `cis-2.0`. Write down the `fail` number: it is the value of `master-fail` in the evidence. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01 --keep
```

The check `kube-bench-master-report` passes.

## Step 2: Remove cluster-admin from beacon-ci

List the bindings to `cluster-admin`:

```sh
kubectl get clusterrolebindings,rolebindings -A -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .kind + " " + .metadata.name + " -> " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
```

Besides the bindings of the built-in groups, one binding names `orbit/beacon-ci`. Its name is `orbit-beacon-ci-admin`. Delete it:

```sh
kubectl delete clusterrolebinding orbit-beacon-ci-admin
kubectl auth can-i '*' '*' -n orbit --as=system:serviceaccount:orbit:beacon-ci
```

The answer is `no`. The check `beacon-ci-no-admin` passes.

## Step 3: Fix the beacon and relay pods

One patch removes the token mount from both Deployments. A second patch removes the privileged setting and the shared process namespace from `beacon`:

```sh
kubectl -n orbit patch deployment beacon --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n orbit patch deployment relay --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n orbit patch deployment beacon --type=json -p '[{"op":"remove","path":"/spec/template/spec/hostPID"},{"op":"remove","path":"/spec/template/spec/containers/0/securityContext/privileged"}]'
kubectl -n orbit rollout status deployment/beacon --timeout=120s
kubectl -n orbit rollout status deployment/relay --timeout=120s
```

Check the result: the pods have no token volume and none is privileged:

```sh
kubectl -n orbit get pods -o json | jq -r '.items[] | .metadata.name + " token-volumes=" + ([.spec.volumes[]? | select(.name | startswith("kube-api-access"))] | length | tostring) + " hostPID=" + ((.spec.hostPID // false) | tostring)'
```

Every line shows `token-volumes=0` and `hostPID=false`. The checks `pods-not-privileged`, `tokens-not-mounted` and `workloads-available` pass.

## Step 4: Enforce the baseline level

A server-side dry run shows whether existing pods would break the level:

```sh
kubectl label --dry-run=server --overwrite namespace orbit pod-security.kubernetes.io/enforce=baseline
```

The API server prints no warning about existing pods, because the pods are fixed. Enforce it:

```sh
kubectl label --overwrite namespace orbit pod-security.kubernetes.io/enforce=baseline
```

The check `orbit-enforces-policy` passes.

## Step 5: Record the evidence

Get the version and the time:

```sh
kubectl version -o json | jq -r '.serverVersion.gitVersion'
date -u +%Y-%m-%dT%H:%M:%SZ
```

Save this as `assessment-evidence.yaml`. Replace the version, the time and `master-fail` with your own values. Keep `master-fail` as a quoted string:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: assessment-evidence
  namespace: orbit
data:
  scope: "namespace orbit; workloads beacon and relay; control plane by kube-bench"
  kubernetes-version: "v1.35.8"
  observed-at: "2026-11-03T10:15:00Z"
  benchmark: "cis-2.0"
  master-fail: "12"
  "5.1.1": "PASS: beacon-ci has no binding to cluster-admin"
  "5.1.6": "PASS: beacon and relay pods have no token volume"
  "5.2.1": "PASS: orbit enforces the baseline Pod Security level"
  "5.2.2": "PASS: no pod in orbit has a privileged container"
  "5.2.3": "PASS: no pod in orbit shares the host process namespace"
```

The number 12 above is only a placeholder for the format. Apply it and grade:

```sh
kubectl apply -f assessment-evidence.yaml
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01
```

All seven checks pass. Clean up with `astrona destroy ats-046-capstone-010`.
