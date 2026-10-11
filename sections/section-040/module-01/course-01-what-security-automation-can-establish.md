---
draft: true
exam_objectives:
  - Automation and Tooling
---
# What Security Automation Can Establish

A scanner reports that `scout` has a risky privilege setting. An admission rule can reject a future Pod with that setting, while a runtime detector can observe selected behavior after execution. These tools occupy different decision points. Their existence does not mean all three effects occurred.

## Scan, Prevent And Detect

Configuration scanning compares inspected data with rules. It can identify a known setting or deviation, but coverage depends on the resources and versions examined. A rule written for another platform release can be misleading if applied without context. Record the scanner, rule set and target identity with the result.

Policy enforcement acts at a decision point, such as resource admission or artifact promotion. It needs matching scope, trusted implementation and defined failure behavior. A rule configured only to report is not equivalent to a rule configured to reject.

Runtime detection observes supported process, file or network behavior during execution. It can reveal activity outside the source declaration, but sensors, collection and interpretation have limits. A detector may alert after harm begins, and absence of an alert does not prove every action was safe.

## Interpreting A Finding

A finding is evidence that a rule matched or an observation met a condition. Determine whether the condition is present in the effective environment, whether the rule addresses the actual threat and whether an approved exception applies. A false positive is a reported problem that does not represent the claimed issue in context; a false negative is an issue the method failed to report.

For example, a source manifest may contain a restrictive field while the admitted object differs through defaulting or mutation. A NetworkPolicy can be present without enforcement. A scan of file text alone cannot establish all runtime behavior. Choose evidence suited to the control's boundary.

Prioritize findings through consequence, exposure and feasible misuse rather than only a severity label detached from the workload. The relevant authority and data can make one deviation more important than another superficially similar result.

## Drift And Reproducible Correction

Control drift is a difference between approved intent and actual configuration. An emergency live change can weaken a setting; an upgrade can change defaults; an old exception can expand beyond its original purpose. Automated comparison helps discover the difference, while ownership determines the appropriate correction.

Record repairs in the authoritative configuration source so reconciliation does not restore the defect. A manual change that temporarily clears a scanner result can be overwritten later. Verify the effective resource and intended behavior after correction rather than merely rerunning the same source-text check.

## Exceptions And Evidence Quality

An exception should state the protected asset, reason, scope, owner, compensating measures and review point. Automation can identify expired exceptions or missing evidence, but the business and technical risk decision still needs accountable ownership. Hiding an exception from reports does not reduce its consequence.

Retain results with enough context to interpret them: time, target, version, rule and observed state. Protect sensitive output and the integrity of stored evidence. A report with no target identity cannot confidently establish which environment was assessed.

## Continuous Assurance

Run relevant checks as configurations, artifacts and vulnerability knowledge change. Combine pipeline, admission and runtime evidence where each adds a useful property. Do not install overlapping tools simply to maximize count; define the question and decision each one supports.

The result should be a maintained loop of observation, interpretation, correction and verification. Automation supplies repeatability and timely evidence, while accurate scope and accountable decisions turn that evidence into meaningful security work.

## Common pitfalls

> [!WARNING]
> A scan is not enforcement, and detection is not proof that harm was prevented. Findings need scope and version context; fixes must persist in the authoritative source and be verified against effective behavior.
