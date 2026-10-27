# Security

## Reporting

Email [charlesmphahlele5@gmail.com](mailto:charlesmphahlele5@gmail.com). Please do not open a public issue that contains a secret, a state file or a live account id.

## What this repository does

GitHub Actions assumes AWS roles with OIDC. There are no long-lived cloud keys in the workflow. RDS generates the database password. Customer managed keys encrypt state, the database, the container registry, logs and the secret. Buckets deny non-TLS requests. The database requires SSL.

Details and the accepted exceptions are in [docs/adr/003-secrets-and-oidc.md](docs/adr/003-secrets-and-oidc.md) and [docs/adr/004-security-scanning.md](docs/adr/004-security-scanning.md).

## What the repository owner turns on

These are GitHub and account settings. Terraform in this repository does not switch them on.

- Secret scanning and push protection on the repository
- Dependabot security updates
- Branch protection on `main`, including a required status check and a pull request review
- GitHub environments `dev` and `prod` with required reviewers, before `TF_APPLY_ENABLED` or `TF_APPLY_PROD_ENABLED` is set
- MFA on the AWS account root user
- CloudTrail and GuardDuty at account level, outside this stack
- A budget alarm. The Budgets API lives in `us-east-1`, so this stack does not create one

## Self-review

This is not an official AWS Well-Architected review.

| Area | What this stack does | What it leaves |
| --- | --- | --- |
| Identity | OIDC, no access keys, deny user and key creation | Plan can write state. Apply policy size is unverified against the 10,240 character quota. |
| Network | Private tasks, locked-down security groups, no public database | NAT egress to 0.0.0.0/0 on port 443. No WAF. No interface endpoints. |
| Data | Encrypted at rest, SSL forced, password not in git | Backups have not been restored against a live account. |
| Operations | fmt, validate, lint, test, scan on every pull request | Plan and apply are off until repository variables are set. The 5xx alarm has no notification target. |
| Cost | Dev is Spot, one NAT gateway, single-AZ | Prices in the README are estimates. Confirm them before apply. |

## History

The original commit contains a local Compose password (`appsecret`) that gitleaks did not flag. No cloud access key was found. Do not reuse that Compose password.
