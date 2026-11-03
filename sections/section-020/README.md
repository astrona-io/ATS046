---
draft: true
exam_objectives:
  - Threat Modelling Frameworks
---
# Section 020: Threat Modelling Frameworks

This section teaches you to find, rank and reduce threats to a Kubernetes application in a repeatable way. You will draw a system, ask structured questions about it, follow an attack path through a cluster and cut that path with controls you can prove.

**Exam objective covered:** Threat Modelling Frameworks

---

## What You Will Master

- Name the assets, data flows and trust boundaries of a Kubernetes application.
- Ask the six STRIDE questions at each trust boundary without treating the categories as a risk score.
- Pick a mitigation that matches a specific finding and prove it with a request.
- Write down residual risk and update the model when the design changes.
- Describe MITRE ATT&CK tactics and techniques and the Kubernetes threat matrix.
- Follow an attack path from a foothold in a pod to the node.
- Break the path with RBAC, `automountServiceAccountToken`, a securityContext and a NetworkPolicy.

---

## The Learning Path

### 1. Structured Threat Modelling
*   **Module Reader:** **[Module 1: Structured Threat Modelling](./module-01/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-01/playground` - kind cluster, no extra tools. Namespaces `starfleet` and `outpost` run the Starfleet workloads. The faults stay in place on purpose: an over-broad RoleBinding for `scout`, a privileged `probe` and no NetworkPolicy.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-01/playground
    ```
*   **Lab:** `sections/section-020/module-01/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-01/labs/lab-01
    astrona submit -c .
    ```

### 2. Kubernetes Attack Paths And MITRE ATT&CK
*   **Module Reader:** **[Module 2: Kubernetes Attack Paths And MITRE ATT&CK](./module-02/course.md)**
*   **Hands-on Playground:** `sections/section-020/module-02/playground` - kind cluster, no extra tools. A privileged `shuttle` pod with a hostPath mount and a Role that lets it read Secrets.
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-02/playground
    ```
*   **Lab:** `sections/section-020/module-02/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/module-02/labs/lab-01
    astrona submit -c .
    ```

### Section Capstone Challenge
*   **Comprehensive Challenge:** Threat Modelling Frameworks Capstone - `sections/section-020/capstone/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS046.git -c sections/section-020/capstone/labs/lab-01
    astrona submit -c .
    ```
*   **Hands-on Objective:** Reduce the threats you found in a cluster that has a cluster-admin binding, mounted tokens, a privileged pod and an open service, and record the residual risk for three STRIDE categories. The grader checks live cluster state.

### Knowledge Check
*   **Quiz:** 10 questions in `sections/section-020/quiz.yaml`. The pass score is 70 percent.
