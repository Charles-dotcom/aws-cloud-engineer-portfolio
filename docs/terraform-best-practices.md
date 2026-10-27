# Terraform conventions in this repository

- One `terraform` block per module, in `versions.tf`. The AWS provider is pinned to `6.70.0`. Terraform is `>= 1.9.0, < 2.0.0`.
- Commit `.terraform.lock.hcl`. Do not commit `.terraform/`, state or plans.
- Account id comes from `aws_caller_identity`. Region, owner and cost centre are variables. Example files use the literal `ACCOUNT_ID`.
- Names are `{project}-{environment}` plus a short suffix. Tags are `ManagedBy`, `Project`, `Environment`, `Owner` and `CostCenter`.
- Modules expose variables with descriptions and validation. Production rules that must not be skipped live in `terraform_data.prod_guardrails`, not in a comment.
- Security group rules are standalone resources, so groups do not gain a default allow-all egress.
- `make fmt`, `make validate`, `make lint` and `make terraform-test` are the local commands. CI runs them through `make check`.
