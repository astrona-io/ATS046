# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without being run, so the text describes what you should see instead of showing recorded output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-01/labs/lab-01
```

`astrona submit` right after the start shows that the `app-still-works` check already passes. It stays your guard: it fails if a fix breaks the application.

## Step 1: Replace the edit grant for scout

The RoleBinding `scout-edit` gives `scout` the built-in `edit` ClusterRole in `starfleet`. Delete it, then create a `Role` that allows `get` on one ConfigMap by name and bind it:

```sh
kubectl -n starfleet delete rolebinding scout-edit
kubectl create role scout-config-reader -n starfleet --verb=get --resource=configmaps --resource-name=scout-config
kubectl create rolebinding scout-config-reader -n starfleet --role=scout-config-reader --serviceaccount=starfleet:scout
```

Check one allowed and one forbidden action:

```sh
kubectl auth can-i get configmaps/scout-config -n starfleet --as=system:serviceaccount:starfleet:scout
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:scout
```

The first command prints `yes` and the second prints `no`. Run `astrona submit --keep`; the check `scout-least-privilege` should pass.

## Step 2: Allow only shuttle to reach probe

A NetworkPolicy selects pods and lists the traffic they accept. Once a policy selects the `probe` pods for ingress, everything it does not allow is dropped. The port in a policy is the container port of the pod (`8080`), not the Service port (`80`).

Save this as `networkpolicy-probe-allow-shuttle.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: probe-allow-shuttle
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: probe
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: shuttle
      ports:
        - protocol: TCP
          port: 8080
```

Apply it:

```sh
kubectl apply -f networkpolicy-probe-allow-shuttle.yaml
```

Then prove it with real requests. The first request must return status `200`. The other two must fail or time out after four seconds, and `curl` prints `000` for a failed connection:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
kubectl -n starfleet exec deploy/caller -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
```

A policy that allows the whole `starfleet` namespace is the plausible wrong fix: it lets `caller` in. Run `astrona submit --keep`; `probe-accepts-only-shuttle` should pass.

## Step 3: Harden the probe container

The container is privileged and runs as user 0. Replace its `securityContext`. A numeric `runAsUser` is needed because `runAsNonRoot` cannot verify a user given by name.

```sh
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/securityContext","value":{"runAsNonRoot":true,"runAsUser":65534,"runAsGroup":65534,"allowPrivilegeEscalation":false,"privileged":false,"capabilities":{"drop":["ALL"]},"seccompProfile":{"type":"RuntimeDefault"}}}]'
kubectl -n starfleet rollout status deployment/probe
```

The patch changes the pod template, so the Deployment starts a new pod and removes the old one. The grader reads the new pod, so wait for the rollout. Check the user of the new pod:

```sh
kubectl -n starfleet get pod -l app=probe -o jsonpath='{.items[0].spec.containers[0].securityContext.runAsUser}{"\n"}'
```

The command prints `65534`. Run `astrona submit`; all four checks should pass.

## Why these fixes

Each fix breaks one step of one threat. The RBAC change shrinks what a stolen `scout` token can do. The NetworkPolicy removes a network path that STRIDE flagged as information disclosure. The `securityContext` removes the node-level power a compromised `probe` process would have. None of them removes the threat completely: a compromised `shuttle` can still call `probe`, and that is residual risk to record in the threat model.
