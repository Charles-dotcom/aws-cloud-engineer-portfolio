# ADR 001: One workload, not a catalogue

Status: Accepted
Date: 27 October 2026

## Context

The first commit described a catalogue: a reusable VPC module, a static website, Azure, landing-zone service control policies, and workflows that were not in the tree. The code that was committed is one AWS workload: a VPC, a load balancer, ECS and RDS, copied three times for dev, staging and prod. That copy did not validate, because every module declared `terraform` twice.

A portfolio that claims files it does not contain is worse than a smaller one that runs.

## Decision

Keep the workload. Delete the catalogue from the documentation. Compose the platform once in `infrastructure/modules/workload` and call it from thin environment roots. Dev, staging and prod differ by variables, including a production guardrail that fails the plan when the expensive controls are off.

Do not add Azure, a static site, GuardDuty, CloudTrail, a budget resource or interface VPC endpoints in this change. Those are real follow-ups. They are not required to show the judgement in the workload that is already here.

## Consequences

A reader can clone the repository and run `make check`. They cannot browse a directory of unrelated examples. Account-wide controls stay with the account owner, because this stack should not be the thing that turns on CloudTrail or GuardDuty for every resource in the account.
