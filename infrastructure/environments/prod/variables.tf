variable "aws_region" {
  description = "AWS region. af-south-1 keeps data in South Africa. Confirm the cost before apply."
  type        = string
  default     = "af-south-1"
}

variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "portfolio"
}

variable "environment" {
  description = "Fixed to prod."
  type        = string
  default     = "prod"

  validation {
    condition     = var.environment == "prod"
    error_message = "This root module is prod."
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
  description = "VPC CIDR for prod. Distinct from dev and staging."
  type        = string
  default     = "10.30.0.0/16"
}

variable "availability_zones" {
  description = "Three zones, one NAT gateway each."
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b", "af-south-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Must be false in prod. One NAT gateway per zone."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Flow logs are on in prod."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Flow log retention. 90 days balances a portfolio bill against a longer compliance window."
  type        = number
  default     = 90
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
  default     = 1024
}

variable "task_memory" {
  description = "Fargate memory in MiB."
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Autoscaling minimum."
  type        = number
  default     = 3
}

variable "max_capacity" {
  description = "Autoscaling maximum."
  type        = number
  default     = 6
}

variable "use_spot" {
  description = "Must be false in prod."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Required. There is no default, so prod cannot be planned on HTTP."
  type        = string
}

variable "enable_alb_access_logs" {
  description = "ALB access logs. Required in prod."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Application log retention."
  type        = number
  default     = 90
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
  default     = "db.t3.medium"
}

variable "multi_az" {
  description = "Must be true in prod."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention."
  type        = number
  default     = 14
}

variable "deletion_protection" {
  description = "Must be true in prod."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Performance Insights at the free seven-day retention."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Adds a small CloudWatch charge not included in the README estimate."
  type        = number
  default     = 60
}

variable "skip_final_snapshot" {
  description = "Must be false in prod."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Wait for the maintenance window."
  type        = bool
  default     = false
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
