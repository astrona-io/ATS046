# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. This lab was written and checked with static checks only (it has not been run), so the outputs below are described and not copied.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-01/labs/lab-01
```

Paste the `trivy_scan` helper from the question into your terminal.

## Step 1: Scan and read the findings

```sh
trivy_scan --severity HIGH,CRITICAL
```

Trivy prints one block for each file. The header of each block names the file (`live/probe.yaml`, `live/scout.yaml`, `live/shuttle.yaml`), its type `kubernetes`, and the counts of passed and failed checks. Each failure shows the check ID, the severity and the lines of the Deployment that caused it. Look for `KSV-0017` in `live/probe.yaml` and `KSV-0014` in `live/shuttle.yaml`. The Deployment `scout` lists several checks because it sets no `securityContext`.

## Step 2: Remove the privileged setting from probe

A JSON patch replaces one value and keeps the rest of the Deployment:

```sh
kubectl -n starfleet patch deployment probe --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/securityContext/privileged","value":false}]'
kubectl -n starfleet rollout status deployment/probe
```

The first command prints `deployment.apps/probe patched`. The second waits until the new pod is ready. The Deployment controller replaces the pod, so the privileged pod is gone when the rollout ends.

## Step 3: Harden scout

The `podinfo` image declares its user by name only, so the pod needs a numeric `runAsUser`. The image user has the ID `100`. A strategic merge patch adds the fields and keeps the rest:

```sh
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"scout","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n starfleet rollout status deployment/scout
```

Grade the first two fixes:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-01/labs/lab-01 --keep
```

The checks `probe-not-privileged`, `scout-hardened`, `services-still-answer` and `shuttle-not-changed` pass. `exception-recorded` still fails.

## Step 4: Record the exception

`shuttle` writes `/tmp/last-run`, so a read-only root file system would break it. Record the accepted risk instead of hiding it. The date must come from today's date. On Linux, run `date -u -d '+60 days' +%Y-%m-%d`. On macOS, run `date -u -v+60d +%Y-%m-%d`. Replace `<EXPIRY>` in the file with the result.

Save this as `configmap-trivy-exceptions.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trivy-exceptions
  namespace: tools
data:
  trivyignore.yaml: |
    misconfigurations:
      - id: KSV-0014
        paths:
          - "live/shuttle.yaml"
        statement: "shuttle writes /tmp/last-run; owner starfleet-ops; compensating control: non-root user and all capabilities dropped"
        expired_at: <EXPIRY>
```

Apply it:

```sh
kubectl apply -f configmap-trivy-exceptions.yaml
```

Then check the result:

```sh
trivy_scan --severity HIGH,CRITICAL
```

Trivy no longer lists `KSV-0014` for `live/shuttle.yaml`. The finding is accepted for 60 days and then shows again. If Trivy still lists it, compare the `paths` value with the file name in the Trivy block header, because the ignore matches that name.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-040/module-01/labs/lab-01
```

All five checks pass. Then remove the lab:

```sh
astrona destroy ats-046-lab-040-01
```
