terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.70.0"
    }
  }

  # First apply uses local state. After the bucket exists, copy
  # backend.s3.tf.example to backend.s3.tf, fill it in, and run
  # terraform init -migrate-state. See docs/adr/002-remote-state.md.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project
      Environment = "bootstrap"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}
