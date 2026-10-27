variable "project" {
  description = "Short project name used in resource names. Lowercase."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,12}$", var.project))
    error_message = "project must be 2-13 characters so project-environment stays within name limits."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "aws_region" {
  description = "AWS region for this stack."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like af-south-1."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR. Each environment should use a distinct range."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for this environment."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per zone."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per zone."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "One NAT gateway instead of one per zone."
  type        = bool
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs."
  type        = bool
}

variable "flow_log_retention_days" {
  description = "Flow log retention in days."
  type        = number
}

variable "container_image" {
  description = "Immutable container image to run."
  type        = string
}

variable "container_port" {
  description = "Container port."
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate CPU units."
  type        = number
}

variable "task_memory" {
  description = "Fargate memory in MiB."
  type        = number
}

variable "desired_count" {
  description = "Initial task count."
  type        = number
}

variable "min_capacity" {
  description = "Minimum task count."
  type        = number
}

variable "max_capacity" {
  description = "Maximum task count."
  type        = number
}

variable "use_spot" {
  description = "Use Fargate Spot."
  type        = bool
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Required when environment is prod."
  type        = string
  default     = ""
}

variable "enable_alb_access_logs" {
  description = "Store ALB access logs."
  type        = bool
}

variable "log_retention_days" {
  description = "Application log retention in days."
  type        = number
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username. The password is managed by RDS."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "multi_az" {
  description = "RDS Multi-AZ."
  type        = bool
}

variable "backup_retention_days" {
  description = "RDS backup retention."
  type        = number
}

variable "deletion_protection" {
  description = "Protect the database and the load balancer from deletion."
  type        = bool
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights."
  type        = bool
}

variable "monitoring_interval" {
  description = "RDS enhanced monitoring interval. 0 disables it."
  type        = number
}

variable "skip_final_snapshot" {
  description = "Skip the final RDS snapshot on destroy."
  type        = bool
}

variable "apply_immediately" {
  description = "Apply RDS changes immediately."
  type        = bool
}

variable "tags" {
  description = "Tags applied to every resource in the stack."
  type        = map(string)
  default     = {}
}
