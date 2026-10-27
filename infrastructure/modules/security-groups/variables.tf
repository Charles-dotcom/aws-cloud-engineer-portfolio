variable "name" {
  description = "Name prefix for the three security groups."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}$", var.name))
    error_message = "name must be 2-23 characters, lowercase, and start with a letter."
  }
}

variable "vpc_id" {
  description = "VPC that owns the security groups."
  type        = string
}

variable "app_port" {
  description = "TCP port the application container listens on."
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "db_port" {
  description = "TCP port PostgreSQL listens on."
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port < 65536
    error_message = "db_port must be between 1 and 65535."
  }
}

variable "alb_ingress_cidr" {
  description = "CIDR allowed to reach the load balancer. Defaults to the public internet."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.alb_ingress_cidr, 0))
    error_message = "alb_ingress_cidr must be a valid IPv4 CIDR."
  }
}

variable "tags" {
  description = "Tags merged onto every security group."
  type        = map(string)
  default     = {}
}
