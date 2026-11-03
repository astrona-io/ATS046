# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was built without being run, so the text describes what you should see instead of showing recorded output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/capstone/labs/lab-01
```

## Step 1: Remove the cluster-admin grant

The `ClusterRoleBinding` is named `scout-admin`. Delete it and check:

```sh
kubectl delete clusterrolebinding scout-admin
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:scout
```

The last command prints `no`. Run `astrona submit --keep`; `no-cluster-admin` should pass.

## Step 2: Remove the tokens and harden scout

Both changes to `scout` are in its pod template, and the token change for `shuttle` is one field. Save this as `deployment-scout.yaml`. It replaces the `scout` Deployment: the `hostPath` volume, its mount and the `privileged` flag are gone, and the pod has no token.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: starfleet
  labels:
    app: scout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      serviceAccountName: scout
      automountServiceAccountToken: false
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
          securityContext:
            runAsNonRoot: true
            runAsUser: 10001
            runAsGroup: 10001
            allowPrivilegeEscalation: false
            privileged: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
            limits:
              memory: 64Mi
```

Apply it, patch `shuttle`, and wait for both rollouts:

```sh
kubectl apply -f deployment-scout.yaml
kubectl -n starfleet patch deployment shuttle --type=merge -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet rollout status deployment/shuttle
```

Check one of the new pods. The command prints `10001`:

```sh
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].spec.containers[0].securityContext.runAsUser}{"\n"}'
```

Run `astrona submit --keep`; `tokens-not-mounted` and `scout-hardened` should pass.

## Step 3: Allow only shuttle to reach probe

Save this as `networkpolicy-probe-allow-shuttle.yaml`. The port is the container port of `probe` (`8080`), not the Service port.

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

Prove it with real requests. The first prints `200`; the other two print `000` after four seconds:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
kubectl -n starfleet exec deploy/caller -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://probe.starfleet.svc/get
```

## Step 4: Record the residual risk

Each mitigation leaves something possible. Write that down in a ConfigMap. Save this as `configmap-residual-risk.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: residual-risk
  namespace: starfleet
data:
  spoofing: A stolen shuttle pod can still call probe, because the policy trusts a pod label and not a verified identity.
  information-disclosure: Anyone with a shell in shuttle can still read the responses of probe, because there is no encryption between the pods.
  elevation-of-privilege: A flaw in the scout process still runs with the container rights, which are now unprivileged but not zero.
```

Apply it:

```sh
kubectl apply -f configmap-residual-risk.yaml
```

Run `astrona submit`; all five checks should pass. The wording is yours. The grader only checks that each key holds a sentence of at least 40 characters without a placeholder word.
