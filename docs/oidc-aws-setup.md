# First apply

This spends money. Read the cost table in the [README](../README.md) first. Nothing in CI applies until you set the variables below.

## 1. Bootstrap, locally, once

```bash
cd infrastructure/bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit owner and cost_center if you need to. Leave github_repository as this repo.
terraform init
terraform plan
terraform apply
```

The first state file is local. Copy the outputs: state bucket, lock table, KMS key ARN, plan role ARN, apply role ARNs, and the workload boundary ARN.

Then copy `backend.s3.tf.example` to `backend.s3.tf`, replace `ACCOUNT_ID` and `KEY_ID`, and run:

```bash
terraform init -migrate-state
```

`terraform.tfvars` and `backend.s3.tf` are gitignored.

## 2. Create the repository, then push the image

The ECR repository and the ECS service are the same apply. The tasks cannot start until an immutable image is already in the repository. Do it in three steps. The service rejects a `:latest` tag and an untagged URI.

```bash
cd infrastructure/environments/dev
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Replace `ACCOUNT_ID` and `KEY_ID` in those files. Set `permissions_boundary_arn` from the bootstrap output. Set `container_image` to the URI you are about to push. The account id is the one from `aws sts get-caller-identity`. Do not commit it.

```bash
terraform init -backend-config=backend.hcl
terraform apply -target=module.workload.module.ecs.aws_ecr_repository.this
```

That creates an empty repository and nothing else. Build and push from `apps/api`:

```bash
aws ecr get-login-password --region af-south-1 \
  | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.af-south-1.amazonaws.com
docker build -t ACCOUNT_ID.dkr.ecr.af-south-1.amazonaws.com/portfolio-dev:1.0.0 .
docker push ACCOUNT_ID.dkr.ecr.af-south-1.amazonaws.com/portfolio-dev:1.0.0
```

Then run a full `terraform apply` in the dev directory. Later pushes can use the `Build and push dev image` job, which is off until `TF_APPLY_ENABLED` is `true`. It pushes `portfolio-dev:<git sha>`. Point `CONTAINER_IMAGE` at that tag before the next apply.

## 3. Dev root

Plan before you apply, and only apply if you accept the cost in the README.

Staging is the same shape and is not wired to CI. Prod will not plan without an ACM certificate ARN in `af-south-1`, and its apply role cannot change dev.

## 4. OIDC subject

The trust policy expects the classic subject:

```text
repo:Charles-dotcom/aws-cloud-engineer-portfolio:pull_request
repo:Charles-dotcom/aws-cloud-engineer-portfolio:ref:refs/heads/main
repo:Charles-dotcom/aws-cloud-engineer-portfolio:environment:dev
```

This repository was created on 19 June 2026. GitHub's immutable subject-claim change on 15 July 2026 does not apply unless the repository opted in. If a sample token shows `repo:Charles-dotcom@80262628/aws-cloud-engineer-portfolio@1274291282:...`, update `github_repository` handling in the trust policy before CI can assume the role.

AWS ignores the GitHub OIDC thumbprint. The provider still sets one, because the API requires it.
