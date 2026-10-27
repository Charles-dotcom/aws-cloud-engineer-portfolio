# ADR 002: Remote state, created by a local first apply

Status: Accepted
Date: 27 October 2026

## Context

Environment roots need a remote backend with a lock, or two people can apply at once and lose a state update. The backend bucket cannot exist before the first apply, and inventing a second bootstrap tool is more machinery than this repository needs.

The previous backend name was `YOUR_COMPANY-terraform-state`. That string is not a valid bucket name, and it was not the bucket the stack created.

## Decision

`infrastructure/bootstrap` starts with local state. It creates:

- a versioned, encrypted, private state bucket named `{project}-tfstate-{account_id}`
- a private log bucket for that bucket's access logs
- a DynamoDB lock table `{project}-terraform-locks` with point-in-time recovery
- a customer managed key for both

Terraform 1.11 can lock with an S3 lock file (`use_lockfile`). This stack keeps DynamoDB. A lock file lives in the state bucket, so the plan role would need `s3:PutObject` there. The plan role is read-only on state objects and writes only the lock table. That split is the point of the table.

The account id comes from `aws_caller_identity`. It is not committed. After the first apply, copy `backend.s3.tf.example` to `backend.s3.tf` (gitignored) and run `terraform init -migrate-state`.

Environment roots declare an empty `backend "s3" {}` and take the rest from `backend.hcl`, which is also gitignored. CI writes that file from repository variables.

The bucket, the lock table and the state key use `prevent_destroy`. The lock table also has deletion protection. Dev workload keys do not. Tear-down is documented in the README.

## Consequences

The first apply is a deliberate local step. Later applies lock. State is not in git. A lost local bootstrap state, before migration, means importing or recreating those objects, so migrate as soon as the bucket exists.
