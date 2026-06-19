# Terraform Best Practices (Cloud Engineer Edition)

## Core Principles

1. **Everything as Code** — No manual clicks in console for production resources.
2. **State is Sacred** — Always use remote backend with locking (S3 + DynamoDB).
3. **Plan before Apply** — Never apply without reviewing the plan (especially in CI).
4. **Modules over Copy-Paste** — Create reusable modules for VPC, security groups, IAM roles, etc.
5. **Naming & Tagging Strategy** — Consistent tags for cost, ownership, environment, compliance.
6. **Least Privilege** — IAM roles, security groups, and bucket policies should be as tight as possible.
7. **Version Everything** — Pin provider versions, use semantic versioning for modules.
8. **Test & Validate** — `terraform validate`, `fmt`, `tfsec`/`checkov`, and integration tests where possible.

## Recommended Project Structure

```
infrastructure/
├── modules/
│   ├── vpc/
│   ├── ecs-service/
│   ├── rds/
│   └── ...
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── global/          # IAM, Route53, shared resources
```

## In This Portfolio

- `terraform/modules/aws-vpc` → Reusable, production-grade networking
- `terraform/examples/static-website` → Full end-to-end example with backend, tagging, security
- Workflows enforce `fmt`, `validate`, `plan` on PRs

## Quick Commands

```bash
terraform fmt -recursive
terraform validate
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq ...   # for automation
terraform apply plan.tfplan
```

## Cost & Security Tips

- Use `lifecycle { prevent_destroy = true }` on critical resources (databases, stateful services)
- Enable **AWS Cost Allocation Tags** and use them in Terraform
- Regularly run `terraform plan` even on unchanged code (drift detection)
- Store Terraform state in a separate, highly restricted AWS account when possible

Adopting these patterns early separates junior cloud engineers from senior ones.
