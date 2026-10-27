variable "name" {
  description = "Name prefix. The load balancer name is name plus -alb and must stay within 32 characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}$", var.name))
    error_message = "name must be 2-23 characters, lowercase, and start with a letter."
  }
}

variable "region" {
  description = "Region for logs and the access-log bucket."
  type        = string
}

variable "account_id" {
  description = "Account id used in the access-log bucket name and policy."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account id."
  }
}

variable "vpc_id" {
  description = "VPC for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the load balancer."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "The load balancer needs at least two public subnets."
  }
}

variable "private_subnet_ids" {
  description = "Private subnets for the tasks."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Tasks need at least two private subnets."
  }
}

variable "alb_sg_id" {
  description = "Security group of the load balancer."
  type        = string
}

variable "ecs_task_sg_id" {
  description = "Security group of the tasks."
  type        = string
}

variable "execution_role_arn" {
  description = "Task execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "Application task role ARN."
  type        = string
}

variable "kms_key_arn" {
  description = "Customer managed key for logs, the repository and the access-log bucket."
  type        = string
}

variable "container_image" {
  description = "Image URI including an immutable tag. Do not use latest."
  type        = string

  validation {
    condition     = length(var.container_image) > 0 && !endswith(var.container_image, ":latest")
    error_message = "container_image must be set and must not use the latest tag."
  }
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "container_port must be between 1 and 65535."
  }
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
  description = "Number of tasks to run."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 1 && var.desired_count <= 10
    error_message = "desired_count must be between 1 and 10 for this portfolio stack."
  }
}

variable "min_capacity" {
  description = "Minimum task count for target tracking."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum task count for target tracking."
  type        = number
  default     = 3

  validation {
    condition     = var.max_capacity <= 20
    error_message = "max_capacity must be 20 or below for this portfolio stack."
  }
}

variable "use_spot" {
  description = "Run on Fargate Spot. Spot can be interrupted, so production leaves this false."
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "HTTP path the load balancer and the container health check call."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Empty serves HTTP only, which production rejects."
  type        = string
  default     = ""

  validation {
    condition     = var.certificate_arn == "" || can(regex("^arn:aws[a-zA-Z-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+$", var.certificate_arn))
    error_message = "certificate_arn must be empty or an ACM certificate ARN."
  }
}

variable "enable_access_logs" {
  description = "Write load balancer access logs to a private bucket."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protect the load balancer from deletion."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch retention for application logs."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
      var.log_retention_days,
    )
    error_message = "log_retention_days must be a CloudWatch Logs retention value."
  }
}

variable "readonly_root_filesystem" {
  description = "Run the container with a read-only root filesystem. apps/api supports this."
  type        = bool
  default     = true
}

variable "environment_variables" {
  description = "Plain environment variables. Do not put secrets here."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secret_variables" {
  description = "Secrets Manager references injected by ECS. valueFrom is an ARN, optionally with a JSON key."
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to the service resources."
  type        = map(string)
  default     = {}
}
