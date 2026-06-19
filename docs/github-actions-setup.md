# GitHub Actions + Terraform + Docker CI/CD Guide

This portfolio includes ready-to-use, secure GitHub Actions workflows.

## Workflows Included

| Workflow              | Trigger                  | Purpose |
|-----------------------|--------------------------|--------|
| `terraform-plan.yml`  | Pull Request             | `terraform plan` + comment result on PR |
| `terraform-apply.yml` | Push to `main`           | `terraform apply -auto-approve` |
| `docker-ci.yml`       | Push/PR to `main` (app changes) | Build multi-stage Docker image → push to Amazon ECR |

## How to Activate

1. **Fork or clone** this repository into your GitHub account/org.
2. **Create the OIDC trust** between GitHub and your AWS account (see `oidc-aws-setup.md`).
3. **Create Terraform backend resources** (S3 bucket + DynamoDB table) — see `backend.tf.example`.
4. Update the `role-to-assume` ARN in all workflow files.
5. Update `AWS_REGION` and `ECR_REPOSITORY` as needed.
6. Push to `main` or open a PR — workflows will run automatically.

## Customizing for Your Projects

### For a different Terraform directory
Change the `working-directory` in the workflow steps.

### For multiple environments (dev/staging/prod)
Use:
- GitHub **Environments** with protection rules
- Different OIDC roles per environment
- `terraform workspace` or separate `tfvars` files + `-var-file`

### Adding security scanning
Add these popular actions after `terraform plan`:

```yaml
- name: Run tfsec
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    working_directory: terraform/examples/static-website
```

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: terraform/examples/static-website
```

## Docker Workflow Notes

The Docker workflow:
- Only builds on changes inside `apps/sample-cloud-app/`
- Uses **OIDC** for ECR push (no secrets)
- Uses Buildx + GitHub Actions cache for fast rebuilds
- Pushes both `:sha` and `:latest` tags

You can extend the job to:
- Run Trivy vulnerability scan
- Deploy to ECS / EKS / App Runner / Lambda (add another job with `needs: build-and-push`)

## Best Practices Demonstrated

- Least-privilege via OIDC
- Plan before apply (PR review gate)
- Immutable infrastructure where possible
- Clear separation between CI (build) and CD (deploy)
- Caching for speed
- Non-root containers
- Multi-stage builds

These are the exact patterns I use and recommend for professional Cloud Engineering work.
