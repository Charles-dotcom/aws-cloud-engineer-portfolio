output "alb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.ecs.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL."
  value       = module.ecs.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.ecs_service_name
}

output "log_group_name" {
  description = "Application log group."
  value       = module.ecs.cloudwatch_log_group
}

output "db_address" {
  description = "Private database hostname."
  value       = module.rds.db_address
}

output "credentials_secret_arn" {
  description = "ARN of the RDS-managed master secret. The secret value is not exported."
  value       = module.rds.credentials_secret_arn
}

output "kms_key_arn" {
  description = "Customer managed key for this environment."
  value       = module.kms.key_arn
}
