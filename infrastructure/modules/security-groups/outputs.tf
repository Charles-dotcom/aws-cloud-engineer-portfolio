output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "ecs_task_sg_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_task.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}
