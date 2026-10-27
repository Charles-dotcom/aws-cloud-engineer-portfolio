# ADR 004: What the scanners are allowed to waive

Status: Accepted
Date: 27 October 2026

## Context

`make check` fails on high and critical Trivy findings and on any Checkov failure. A few findings are properties of this design, not mistakes. A global skip file would hide the next real finding. tfsec is not used. It was archived into Trivy.

## Decision

Trivy config and Checkov both run. A waiver is a comment on the resource, with a reason. The waivers are:

| Check | Where | Why it stays |
| --- | --- | --- |
| AVD-AWS-0053 | Load balancer | The load balancer is the public entry point. |
| AVD-AWS-0054, CKV_AWS_103, CKV2_AWS_20 | HTTP listener | With a certificate the listener redirects to HTTPS. Dev has no certificate yet, so it forwards. Production refuses an empty certificate. |
| AVD-AWS-0104 | Task egress 443 | Tasks reach ECR, CloudWatch Logs and Secrets Manager through the NAT gateway. Interface endpoints are billed per hour per zone and were left out. |
| CKV_AWS_260 | Port 80 on the load balancer | Clients need port 80 so they can be redirected. |
| CKV_AWS_378 | Target group HTTP | TLS ends at the load balancer. Tasks speak HTTP inside the VPC. |
| CKV2_AWS_28 | No WAF | WAF is a separate bill. Add it before real production traffic. |
| CKV2_AWS_5 | Security groups | The groups are attached by the ECS and RDS modules. The graph check does not follow that. |
| CKV_AWS_109, CKV_AWS_111, CKV_AWS_356 | KMS key policy | The account-root `kms:*` statement is how a key policy delegates to IAM. Service use is constrained by account. |
| CKV_AWS_356 | Plan role | The `Resource *` statement is Describe and List. Those actions have no resource-level permission. |
| CKV_AWS_355 | Flow-log role | `logs:DescribeLogGroups` has no resource-level permission. Writes are scoped to the log group. |
| CKV_AWS_118, CKV_AWS_157, CKV_AWS_293 | RDS module | Enhanced monitoring, Multi-AZ and deletion protection are off in dev. The production guardrail requires Multi-AZ and deletion protection. |
| CKV_AWS_338 | Flow logs | A year of retention is a cost decision. Production keeps 90 days. |
| CKV_AWS_18, CKV_AWS_144, CKV2_AWS_62 | Log and state buckets | The access-log bucket does not log to itself. Cross-region replication and event notifications are a cost decision. |

## Consequences

A new high finding fails `make check`. Reviewers can see each waiver next to the resource. WAF, interface endpoints and a longer log retention are follow-ups for a real workload, not for this demonstration.
