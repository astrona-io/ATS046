---
draft: true
exam_objectives:
  - Compliance Frameworks
---
# Frameworks, Scope And Demonstrable Controls

A team must demonstrate that its report service follows defined security requirements. Compliance concerns meeting applicable obligations within an identified scope. Security concerns reducing actual risk to assets. They overlap, but a successful assessment does not establish that every threat is impossible or every application operation is correct.

## Different Kinds Of Guidance

A framework organizes goals, activities or controls. The National Institute of Standards and Technology (NIST) Cybersecurity Framework supports risk management through functions including Govern, Identify, Protect, Detect, Respond and Recover. These functions describe areas of work rather than one Kubernetes setting that implements the whole framework.

International Organization for Standardization / International Electrotechnical Commission (ISO/IEC) 27001 describes requirements for an information security management system. Payment Card Industry Data Security Standard (PCI DSS) addresses security requirements for relevant payment-card environments. A Center for Internet Security (CIS) Benchmark supplies configuration recommendations for a particular technology. These examples have different scopes and assessment meanings; a cluster scan is not equivalent to every organization's complete obligation.

A policy states the organization's intended rule. A technical control implements part of that rule. Evidence demonstrates relevant implementation or activity. For example, a policy can require restricted administrative access, role-based access control (RBAC) can constrain application programming interface (API) actions and an access review can document whether current grants still match approved responsibilities.

## Defining The Assessment Boundary

Specify the systems, data, actors and operating duties included. A managed control plane may have provider evidence for some infrastructure controls, while the customer must demonstrate workload identity and data handling. Provider assurance does not automatically cover the application's code or every customer configuration.

Scope also includes dependencies. Reports stored in an external database, backups in another account and credentials used by a build job can be relevant to the service's protection. Excluding them merely because they are outside Kubernetes can leave a false picture of the full control environment.

Versions and time matter. A configuration result describes the checked environment at a particular point. A change after the assessment can alter the control. Retain the resource or system identity, rule version, observation time and method so evidence can be interpreted accurately.

## Mapping Goals To Evidence

Consider a goal to limit sensitive data access. Technical evidence can include effective roles, workload mounts and backend permissions. Process evidence can include approved ownership and periodic access review. Audit evidence can show selected use or changes. Each contributes a different part of the explanation.

A scanner that reports a setting exists does not necessarily prove it is effective. A declared NetworkPolicy without enforcement is one example. A source file containing a restriction does not prove the deployed object uses it. The assessment should examine actual configuration and behavior appropriate to the control.

Exceptions need a documented reason, owner, scope and review plan. A system may require a narrow privileged component, but an exception for that component should not silently permit every application. Record compensating protections and remaining risk rather than hiding the deviation.

## Compliance And Continued Security

A passed benchmark provides evidence for the rules and version checked. It cannot prove the application authorizes every report request correctly or that all unknown vulnerabilities are absent. Threat modelling and vulnerability response remain necessary alongside compliance work.

Automation can help maintain evidence, while human ownership determines whether controls fit the environment and obligations. A useful compliance explanation connects requirement, implemented control, observed evidence and remaining limitation. That chain is more defensible than treating a green scan as a universal certificate of safety.

## Common pitfalls

> [!WARNING]
> A framework, management standard and configuration benchmark have different scopes. Provider evidence and a passed cluster scan do not automatically establish every application or organizational requirement.
