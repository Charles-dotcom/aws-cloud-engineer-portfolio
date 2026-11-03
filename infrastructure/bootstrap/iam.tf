# CI roles for this stack only.
# Plan reads state and writes only the lock table. It does not put or delete
# state objects. Each apply role can write only its own state prefix and only
# resources named for that environment. Neither role can modify the CI roles
# or the OIDC provider. See docs/adr/003-secrets-and-oidc.md.

module "ci_policies" {
  source = "../modules/ci-policies"

  account_id         = local.account_id
  aws_region         = var.aws_region
  project            = var.project
  github_repository  = var.github_repository
  apply_environments = var.apply_environments
  state_bucket_name  = local.state_bucket_name
  lock_table_name    = local.lock_table_name
  state_kms_key_arn  = module.kms.key_arn
  oidc_provider_arn  = local.oidc_provider_arn
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "${var.project}-workload-boundary"
  description = "Maximum permissions for roles created by an environment apply."
  policy      = module.ci_policies.workload_boundary_json
}

resource "aws_iam_role" "plan" {
  name               = "${var.project}-gha-plan"
  description        = "GitHub Actions plan role for ${var.github_repository}."
  assume_role_policy = module.ci_policies.plan_trust_json

  tags = {
    Name = "${var.project}-gha-plan"
  }
}

resource "aws_iam_role_policy" "plan" {
  name   = "${var.project}-gha-plan"
  role   = aws_iam_role.plan.id
  policy = module.ci_policies.plan_json
}

resource "aws_iam_role" "apply" {
  for_each = toset(var.apply_environments)

  name               = "${var.project}-gha-apply-${each.value}"
  description        = "GitHub Actions apply role for the ${each.value} environment."
  assume_role_policy = module.ci_policies.apply_trust_json[each.value]

  tags = {
    Name = "${var.project}-gha-apply-${each.value}"
  }
}

locals {
  apply_policy_attachments = {
    for pair in setproduct(var.apply_environments, module.ci_policies.apply_policy_groups) :
    "${pair[0]}-${pair[1]}" => {
      environment = pair[0]
      group       = pair[1]
    }
  }
}

resource "aws_iam_policy" "apply" {
  for_each = local.apply_policy_attachments

  name        = "${var.project}-gha-apply-${each.key}"
  description = "GitHub Actions apply permissions (${each.value.group}) for the ${each.value.environment} environment."
  policy      = module.ci_policies.apply_managed_policies[each.value.environment][each.value.group]
}

resource "aws_iam_role_policy_attachment" "apply" {
  for_each = local.apply_policy_attachments

  role       = aws_iam_role.apply[each.value.environment].name
  policy_arn = aws_iam_policy.apply[each.key].arn
}
