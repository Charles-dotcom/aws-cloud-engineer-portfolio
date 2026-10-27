variable "aws_region" {
  description = "Region for the state bucket, lock table and KMS key."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like af-south-1."
  }
}

variable "project" {
  description = "Short project name. Used as the prefix of the state bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,12}$", var.project))
    error_message = "project must be 2-13 lowercase characters."
  }
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "cost_center" {
  description = "Cost centre tag."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the CI roles, as owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false when the account already has one."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider. Required when create_oidc_provider is false."
  type        = string
  default     = ""
}

variable "apply_environments" {
  description = "GitHub environment names that may apply. Each gets its own role."
  type        = list(string)
  default     = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.apply_environments) > 0 && alltrue([for env in var.apply_environments : can(regex("^[a-z][a-z0-9-]{1,20}$", env))])
    error_message = "apply_environments entries must be lowercase names."
  }
}
