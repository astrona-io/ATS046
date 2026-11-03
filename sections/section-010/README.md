---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Section 010: Compliance Frameworks

This section teaches you to tie a security requirement to a control and to evidence that another person can check. You will collect evidence from a cluster with `kubectl`, run the CIS Kubernetes Benchmark with kube-bench and keep a record of the findings and the exceptions.

**Exam objective covered:** Compliance Frameworks

---

## What You Will Master

- Distinguish a framework, a benchmark, a policy and an evidence record.
- State the scope, the versions and the time of an assessment, and name who owns each layer.
- Collect evidence for `cluster-admin` bindings, service account tokens and privileged containers from the Kubernetes API.
- Fix a failing control and prove that the fix reached the running pods.
- Run kube-bench as a Job and read its statuses `PASS`, `FAIL`, `WARN` and `INFO`.
- Explain why the manual checks of the policies target report `WARN`.
- Build a small summary of a report with `jq` and record the failures the team accepts as exceptions.

---

## The Learning Path

### 1. Compliance Scope And Control Evidence
*   **Module Reader:** **[Module 1: Compliance Scope And Control Evidence](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-010/module-01/playground` - kind cluster, `jq` on your machine. The Starfleet workloads run with three deliberate control failures: a `cluster-admin` binding for `shuttle`, a privileged `probe` and token mounts on every pod. No evidence record exists yet.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/playground
    ```
*   **Lab:** `sections/section-010/module-01/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Auditing A Cluster Against The CIS Kubernetes Benchmark
*   **Module Reader:** **[Module 2: Auditing A Cluster Against The CIS Kubernetes Benchmark](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-010/module-02/playground` - kind cluster, `jq` on your machine. The kube-bench image is preloaded and the namespace `compliance` is empty. kube-bench is not installed; you run it as a Job.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/playground
    ```
*   **Lab:** `sections/section-010/module-02/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Compliance Frameworks Capstone - `sections/section-010/capstone/labs/lab-01` (UNTESTED)
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-010/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Assess the namespace `orbit` and the control plane against the benchmark `cis-2.0`. Run kube-bench for the `master` target in the namespace `audit`, remove a `cluster-admin` binding, stop token mounts, remove privileged and host-sharing pods, enforce the Pod Security level `baseline` and record the evidence in a ConfigMap. The grader checks live cluster state and the Job log.

### Knowledge Check
*   **Quiz:** 10 questions in `sections/section-010/quiz.yaml`. The pass score is 70 percent.
