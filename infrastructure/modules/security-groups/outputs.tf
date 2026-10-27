output "alb_sg_id" {
  description = "Security group ID of the load balancer."
  value       = aws_security_group.alb.id
}

output "ecs_task_sg_id" {
  description = "Security group ID of the application tasks."
  value       = aws_security_group.ecs_task.id
}

output "rds_sg_id" {
  description = "Security group ID of the database."
  value       = aws_security_group.rds.id
}
