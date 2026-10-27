# Contributing

This is a portfolio repository. Small, reviewed changes are welcome.

## Before you open a pull request

```bash
make check
```

That formats and checks Terraform, runs tflint, `terraform test`, the API tests, Trivy, Checkov and gitleaks. It does not call AWS.

- Use [Conventional Commits](https://www.conventionalcommits.org/).
- Do not commit `*.tfvars`, `backend.hcl`, `backend.s3.tf`, `.env`, state, plans or `.terraform/`.
- Do not add a secret, an account id or a long-lived cloud key.
- If you waive a scanner finding, put the comment on the resource and add a row to [docs/adr/004-security-scanning.md](docs/adr/004-security-scanning.md).
- Write documentation in British English.

`pre-commit` is configured in `.pre-commit-config.yaml`. Install it locally if you want the same hooks on commit. CI does not depend on it.

Do not run `terraform apply` from a pull request. Apply runs on `main`, behind a GitHub environment, and only when the matching repository variable is `true`.
