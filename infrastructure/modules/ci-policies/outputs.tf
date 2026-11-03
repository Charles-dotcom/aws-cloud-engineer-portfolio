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
  description = "Full permissions document for each apply role, before it is split for the managed-policy quota."
  value       = { for env, doc in data.aws_iam_policy_document.apply : env => doc.json }
}

output "ec2_actions_without_resource_permissions" {
  description = "EC2 actions this module may allow without an Environment condition. Empty unless AWS gives the action no resource type."
  value       = local.ec2_actions_without_resource_permissions
}

output "apply_policy_groups" {
  description = "Names of the customer managed policies attached to each apply role."
  value       = keys(local.apply_groups)
}

output "apply_managed_policies" {
  description = "Customer managed apply policies keyed by environment and group. Each document is at most 6144 non-whitespace characters."
  value       = local.apply_managed_policies
}

output "policy_character_counts" {
  description = "Non-whitespace character counts of the rendered plan, boundary, trust and apply policies."
  value       = local.policy_character_counts
}

output "workload_boundary_json" {
  description = "Permissions boundary for roles an environment apply creates."
  value       = data.aws_iam_policy_document.workload_boundary.json
}

output "permissions_boundary_arn" {
  description = "ARN the apply policy requires on iam:CreateRole, PutRolePolicy and AttachRolePolicy."
  value       = local.permissions_boundary_arn
}
