variable "name" {
  description = "Name prefix. Kept short so derived load balancer names stay within AWS limits."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}$", var.name))
    error_message = "name must be 2-23 characters, lowercase, and start with a letter."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across. One public and one private subnet are created per zone."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "Use two or three availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone, in the same order."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every public subnet CIDR must be valid."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per availability zone, in the same order."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Every private subnet CIDR must be valid."
  }
}

variable "region" {
  description = "Region used in the S3 gateway endpoint service name."
  type        = string
}

variable "account_id" {
  description = "Account id used to constrain the VPC flow log role."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account id."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for every private subnet. Cheaper, and a single point of failure. Production must set this to false."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs. Off by default because a quiet demo does not need the ingestion bill."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for flow logs. Must be a value CloudWatch accepts."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
      var.flow_log_retention_days,
    )
    error_message = "flow_log_retention_days must be a CloudWatch Logs retention value."
  }
}

variable "kms_key_arn" {
  description = "Customer managed key for the flow log group. Required when flow logs are enabled."
  type        = string
  default     = ""
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary for the flow-log role. Empty when flow logs are off."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags merged onto every resource. Name is added per resource."
  type        = map(string)
  default     = {}
}
