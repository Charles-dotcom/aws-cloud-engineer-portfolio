variable "account_id" {
  description = "12-digit AWS account id."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be 12 digits."
  }
}

variable "aws_region" {
  description = "Region used in workload and state ARNs."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like af-south-1."
  }
}

variable "project" {
  description = "Short project name. Prefix of roles, buckets and the boundary policy."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,12}$", var.project))
    error_message = "project must be 2-13 lowercase characters."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the CI roles, as owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name."
  }
}

variable "apply_environments" {
  description = "GitHub environment names that may apply. Each gets its own policy document."
  type        = list(string)

  validation {
    condition     = length(var.apply_environments) > 0 && alltrue([for env in var.apply_environments : can(regex("^[a-z][a-z0-9-]{1,20}$", env))])
    error_message = "apply_environments entries must be lowercase names."
  }
}

variable "state_bucket_name" {
  description = "Name of the Terraform state bucket."
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB lock table."
  type        = string
}

variable "state_kms_key_arn" {
  description = "ARN of the KMS key that encrypts state."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  type        = string
}
