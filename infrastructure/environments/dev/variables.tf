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
  description = "Fixed to dev. Use the staging or prod root for the other stacks."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "This root module is dev. Use environments/staging or environments/prod for the others."
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
  description = "VPC CIDR for dev."
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "Two zones. Dev uses one NAT gateway in the first."
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "single_nat_gateway" {
  description = "One NAT gateway, to keep the dev bill down."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Flow logs are off in dev."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention used if flow logs are turned on."
  type        = number
  default     = 14
}

variable "container_image" {
  description = "Immutable image URI. Copy terraform.tfvars.example and set this before plan."
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
  default     = 256
}

variable "task_memory" {
  description = "Fargate memory in MiB."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of tasks."
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Autoscaling minimum."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Autoscaling maximum."
  type        = number
  default     = 2
}

variable "use_spot" {
  description = "Fargate Spot. The cost estimate still uses on-demand, because Spot is not guaranteed."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "Optional ACM certificate. Empty keeps dev on HTTP."
  type        = string
  default     = ""
}

variable "enable_alb_access_logs" {
  description = "ALB access logs. Off in dev."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Application log retention."
  type        = number
  default     = 14
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
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Multi-AZ is off in dev."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Deletion protection is off in dev so the stack can be torn down."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Performance Insights at the free seven-day retention."
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring. Off in dev."
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
