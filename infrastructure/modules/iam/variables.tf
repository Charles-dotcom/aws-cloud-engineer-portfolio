variable "name" {
  description = "Name prefix for all IAM resources"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs the ECS execution role can read"
  type        = list(string)
  default     = []
}

variable "task_policy_statements" {
  description = "IAM policy statements for the ECS task role (app-level permissions)"
  type        = list(any)
  default     = []
}

variable "enable_github_actions_role" {
  description = "Create an OIDC role for GitHub Actions deployments"
  type        = bool
  default     = false
}

variable "aws_account_id" {
  description = "AWS account ID (required for GitHub Actions OIDC role)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. my-org/my-repo)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
