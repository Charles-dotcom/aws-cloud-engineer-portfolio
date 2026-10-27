variable "name" {
  description = "Name prefix for the task roles."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}$", var.name))
    error_message = "name must be 2-23 characters, lowercase, and start with a letter."
  }
}

variable "region" {
  description = "Region used in the kms:ViaService condition for Secrets Manager."
  type        = string
}

variable "secrets_arns" {
  description = "Secrets Manager ARNs the execution role may read. Empty disables the extra policy."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "Key the execution role may decrypt, and only via Secrets Manager."
  type        = string
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary required on roles this stack creates. Empty only for local plans before bootstrap has produced the boundary."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to the roles."
  type        = map(string)
  default     = {}
}
