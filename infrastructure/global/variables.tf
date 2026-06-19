variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used in resource naming and tags"
  type        = string
}

variable "owner" {
  description = "Team or person responsible for these resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center or billing tag"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID (used in unique bucket naming)"
  type        = string
}
