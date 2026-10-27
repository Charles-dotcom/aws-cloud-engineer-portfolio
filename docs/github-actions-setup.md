# GitHub Actions

The workflow is `.github/workflows/ci.yml`. On every pull request and every push to `main` it runs `make check`. That job has `contents: read` and does not use AWS.

Plan and apply are off. They start only when repository variables are the string `true`.

| Variable | Purpose |
| --- | --- |
| `TF_PLAN_ENABLED` | Plan dev on pull requests from this repository, and on pushes to `main`. |
| `TF_APPLY_ENABLED` | Apply dev on `main`, in the GitHub environment `dev`. |
| `TF_APPLY_PROD_ENABLED` | Plan and apply prod on `main`, in the GitHub environment `prod`. |
| `AWS_ROLE_ARN_PLAN` | Plan role from the bootstrap output. A variable, not a secret. |
| `AWS_ROLE_ARN_APPLY_DEV` | Apply role for `dev`. |
| `AWS_ROLE_ARN_APPLY_PROD` | Apply role for `prod`. |
| `TF_STATE_BUCKET` | State bucket name. |
| `TF_LOCK_TABLE` | Lock table name. |
| `TF_STATE_KMS_KEY_ARN` | State key ARN. |
| `AWS_REGION` | Optional. Defaults to `af-south-1`. |
| `CONTAINER_IMAGE` | Immutable image URI for dev. |
| `CONTAINER_IMAGE_PROD` | Immutable image URI for prod. |
| `CERTIFICATE_ARN` | ACM certificate for prod. |

Create GitHub environments named `dev` and `prod` and add yourself as a required reviewer before you set the apply variables. Apply downloads the plan artefact from the plan job. It does not plan again.

Fork pull requests cannot assume the plan role. The workflow does not comment on the pull request, so it does not need `pull-requests: write`.

Actions are pinned to commit SHAs. Dependabot opens weekly updates for Actions, pip, Docker and Terraform.

Turn on secret scanning, push protection, Dependabot alerts and branch protection on `main` in the repository settings. Those toggles are not in this workflow.
