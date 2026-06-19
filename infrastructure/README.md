# Infrastructure

Terraform modules and environment configurations for the AWS portfolio project.

## Structure

```
infrastructure/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT, flow logs
│   ├── security-groups/  # ALB, ECS task, RDS SGs (least-privilege)
│   ├── iam/              # Task execution/task roles, GitHub OIDC
│   ├── ecs-service/      # ECR, ECS cluster/service, ALB, auto scaling
│   └── rds/              # RDS Postgres, Secrets Manager, subnet group
├── environments/
│   ├── dev/              # Single NAT, Fargate Spot, t3.micro RDS
│   ├── staging/          # Single NAT, Fargate Spot, t3.small RDS
│   └── prod/             # Multi-AZ NAT + RDS, standard Fargate, t3.medium RDS
└── global/               # S3 state bucket, DynamoDB lock, GitHub OIDC provider
```

## First-Time Setup

1. **Bootstrap state backend** (run once, locally):
   ```bash
   cd global
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```
   Then update `backend "s3"` blocks with the bucket name from the output and run `terraform init -migrate-state`.

2. **Deploy an environment:**
   ```bash
   cd environments/dev
   terraform init
   terraform plan -var="db_username=..." -var="db_password=..."
   terraform apply
   ```

## Key Conventions

| Convention | Detail |
|---|---|
| State backend | S3 + DynamoDB (encrypted, versioned, TLS-only bucket policy) |
| Secrets | Never in `.tfvars` — use `TF_VAR_` env vars or CI secrets |
| Tagging | `ManagedBy`, `Project`, `Environment`, `Owner`, `CostCenter` on every resource |
| Provider pinning | `~> 5.0` — locked to major version |
| Security scanning | `tfsec` + `checkov` run on every PR |
| HTTPS only | HTTP → HTTPS redirect on ALB when `certificate_arn` is set |
| Least-privilege SGs | ALB → ECS task → RDS — no open ingress |

## CI/CD

GitHub Actions workflow at `.github/workflows/terraform.yml`:
- PRs: `fmt check` → `tfsec` → `checkov` → `plan`
- Merge to main: `apply` dev → manual gate → `plan` prod
- Auth via OIDC (no long-lived AWS keys)

## Environment Differences

| Setting | dev | staging | prod |
|---|---|---|---|
| NAT Gateways | 1 | 1 | 1 per AZ |
| Fargate type | SPOT | SPOT | standard |
| RDS Multi-AZ | no | no | yes |
| RDS instance | t3.micro | t3.small | t3.medium |
| Flow logs | off | on | on (90d) |
| Deletion protection | off | off | on |
