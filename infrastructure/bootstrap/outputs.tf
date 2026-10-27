output "state_bucket" {
  description = "State bucket name. Use it as the backend bucket."
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "DynamoDB lock table name."
  value       = aws_dynamodb_table.locks.name
}

output "kms_key_arn" {
  description = "KMS key that encrypts state."
  value       = module.kms.key_arn
}

output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = local.oidc_provider_arn
}

output "plan_role_arn" {
  description = "Role ARN for terraform plan. Store it as the GitHub variable AWS_ROLE_ARN_PLAN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arns" {
  description = "Role ARN per GitHub environment. Store dev and prod as AWS_ROLE_ARN_APPLY_DEV and AWS_ROLE_ARN_APPLY_PROD."
  value       = { for env, role in aws_iam_role.apply : env => role.arn }
}
