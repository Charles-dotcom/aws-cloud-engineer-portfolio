variable "aws_region" { type = string; default = "us-east-1" }
variable "project" { type = string }
variable "environment" { type = string; default = "staging" }
variable "owner" { type = string }
variable "cost_center" { type = string }
variable "aws_account_id" { type = string }
variable "github_repo" { type = string }

variable "vpc_cidr" { type = string; default = "10.20.0.0/16" }
variable "availability_zones" { type = list(string); default = ["us-east-1a", "us-east-1b"] }
variable "public_subnet_cidrs" { type = list(string); default = ["10.20.0.0/24", "10.20.1.0/24"] }
variable "private_subnet_cidrs" { type = list(string); default = ["10.20.10.0/24", "10.20.11.0/24"] }

variable "app_port" { type = number; default = 8080 }
variable "container_image" { type = string }
variable "db_name" { type = string; default = "appdb" }
variable "db_username" { type = string; sensitive = true }
variable "db_password" { type = string; sensitive = true }
