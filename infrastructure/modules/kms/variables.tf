variable "name" {
  description = "Alias suffix. The module creates alias/<name>."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,40}$", var.name))
    error_message = "name must be lowercase, start with a letter, and contain only letters, digits and hyphens."
  }
}

variable "description" {
  description = "Human-readable description stored on the key."
  type        = string
}

variable "account_id" {
  description = "AWS account that owns the key. Used to scope the key policy. Never hard-coded by callers; pass the caller identity."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account id."
  }
}

variable "region" {
  description = "Region the key is used in. CloudWatch Logs requires the regional logs service principal."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "region must look like af-south-1."
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before AWS deletes the key. Minimum 7."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "service_principals" {
  description = "Extra AWS services allowed to use this key, each constrained to this account. CloudWatch Logs is always included."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the key."
  type        = map(string)
  default     = {}
}
