output "alb_dns_name" {
  description = "ALB DNS name — point your dev DNS here"
  value       = module.ecs.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  value       = module.ecs.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.ecs.ecs_service_name
}

output "db_endpoint" {
  description = "RDS endpoint (private, within VPC)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "github_actions_role_arn" {
  description = "Role ARN to use in GitHub Actions OIDC config"
  value       = module.iam.github_actions_role_arn
}
