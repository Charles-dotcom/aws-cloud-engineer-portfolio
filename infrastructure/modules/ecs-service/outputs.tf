output "alb_dns_name" {
  description = "DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL. Push an immutable tag here before expecting healthy tasks."
  value       = aws_ecr_repository.this.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "cloudwatch_log_group" {
  description = "Application log group name."
  value       = aws_cloudwatch_log_group.this.name
}
