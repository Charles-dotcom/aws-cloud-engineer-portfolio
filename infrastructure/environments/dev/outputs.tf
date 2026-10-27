output "alb_dns_name" {
  description = "DNS name of the development load balancer."
  value       = module.workload.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push the immutable image tag here."
  value       = module.workload.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.workload.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.workload.ecs_service_name
}

output "log_group_name" {
  description = "Application log group."
  value       = module.workload.log_group_name
}

output "db_address" {
  description = "Private database hostname."
  value       = module.workload.db_address
}

output "credentials_secret_arn" {
  description = "RDS-managed secret ARN. The password is not an output."
  value       = module.workload.credentials_secret_arn
}
