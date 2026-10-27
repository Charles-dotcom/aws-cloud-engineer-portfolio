variable "aws_region" {
  description = "AWS region. af-south-1 keeps a demo in South Africa. Confirm the cost before apply."
  type        = string
  default     = "af-south-1"
}

variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Fixed to staging."
  type        = string
  default     = "staging"

  validation {
    condition     = var.environment == "staging"
    error_message = "This root module is staging."
  }
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "charles-mphahlele"
}

variable "cost_center" {
  description = "Cost centre tag."
  type        = string
  default     = "portfolio"
}

variable "vpc_cidr" {
  description = "VPC CIDR for staging. Distinct from dev and prod."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two zones. Staging still uses one NAT gateway."
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "single_nat_gateway" {
  description = "One NAT gateway."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Flow logs are on in staging."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Flow log retention."
  type        = number
  default     = 30
}

variable "container_image" {
  description = "Immutable image URI."
  type        = string
}

variable "container_port" {
  description = "Port apps/api listens on."
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Autoscaling minimum."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Autoscaling maximum."
  type        = number
  default     = 4
}

variable "use_spot" {
  description = "Fargate Spot."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "Optional ACM certificate."
  type        = string
  default     = ""
}

variable "enable_alb_access_logs" {
  description = "ALB access logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Application log retention."
  type        = number
  default     = 30
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Master username. RDS generates the password."
  type        = string
  default     = "app"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "multi_az" {
  description = "Multi-AZ is off in staging."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Deletion protection is off in staging."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Performance Insights at the free seven-day retention."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring. Off in staging."
  type        = number
  default     = 0
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply database changes immediately."
  type        = bool
  default     = true
}

variable "permissions_boundary_arn" {
  description = "Workload permissions boundary from the bootstrap output. Required before an apply that creates roles."
  type        = string
  default     = ""
}

variable "alarm_sns_topic_arn" {
  description = "Optional SNS topic for the 5xx alarm."
  type        = string
  default     = ""
}
