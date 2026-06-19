output "alb_dns_name" { value = module.ecs.alb_dns_name }
output "ecr_repository_url" { value = module.ecs.ecr_repository_url }
output "ecs_cluster_name" { value = module.ecs.ecs_cluster_name }
output "ecs_service_name" { value = module.ecs.ecs_service_name }
output "db_endpoint" { value = module.rds.db_endpoint; sensitive = true }
output "github_actions_role_arn" { value = module.iam.github_actions_role_arn }
