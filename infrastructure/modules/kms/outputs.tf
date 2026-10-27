output "key_arn" {
  description = "ARN of the customer managed key."
  value       = local.key_arn
}

output "key_id" {
  description = "ID of the customer managed key."
  value       = local.key_id
}

output "alias_name" {
  description = "Alias name, including the alias/ prefix."
  value       = aws_kms_alias.this.name
}
