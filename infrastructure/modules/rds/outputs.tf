output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "db_address" {
  description = "Hostname of the instance. Reachable only from the application tasks."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the instance listens on."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "credentials_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed master secret. The value is not an output."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
