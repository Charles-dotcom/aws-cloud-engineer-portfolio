output "plan_trust_json" {
  description = "Assume-role policy for the plan role."
  value       = data.aws_iam_policy_document.plan_trust.json
}

output "apply_trust_json" {
  description = "Assume-role policy for each apply role."
  value       = { for env, doc in data.aws_iam_policy_document.apply_trust : env => doc.json }
}

output "plan_json" {
  description = "Permissions policy for the plan role."
  value       = data.aws_iam_policy_document.plan.json
}

output "apply_json" {
  description = "Permissions policy for each apply role."
  value       = { for env, doc in data.aws_iam_policy_document.apply : env => doc.json }
}

output "workload_boundary_json" {
  description = "Permissions boundary for roles an environment apply creates."
  value       = data.aws_iam_policy_document.workload_boundary.json
}

output "permissions_boundary_arn" {
  description = "ARN the apply policy requires on iam:CreateRole, PutRolePolicy and AttachRolePolicy."
  value       = local.permissions_boundary_arn
}
