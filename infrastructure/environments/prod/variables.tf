variable "aws_region" { type = string; default = "us-east-1" }
variable "project" { type = string }
variable "environment" { type = string; default = "prod" }
variable "owner" { type = string }
variable "cost_center" { type = string }
variable "compliance_tag" { type = string; default = "SOC2" }
variable "aws_account_id" { type = string }
variable "github_repo" { type = string }

variable "vpc_cidr" { type = string; default = "10.30.0.0/16" }
variable "availability_zones" { type = list(string); default = ["us-east-1a", "us-east-1b", "us-east-1c"] }
variable "public_subnet_cidrs" { type = list(string); default = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"] }
variable "private_subnet_cidrs" { type = list(string); default = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"] }

variable "app_port" { type = number; default = 8080 }
variable "container_image" { type = string }
variable "certificate_arn" { description = "ACM certificate ARN for HTTPS"; type = string }
variable "db_name" { type = string; default = "appdb" }
variable "db_username" { type = string; sensitive = true }
variable "db_password" { type = string; sensitive = true }
