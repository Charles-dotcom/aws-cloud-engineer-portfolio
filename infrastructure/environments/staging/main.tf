terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "YOUR_COMPANY-terraform-state"
    key            = "environments/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = "${var.project}-${var.environment}"
  cidr_block           = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = true
  enable_flow_logs     = true
  tags                 = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  name     = "${var.project}-${var.environment}"
  vpc_id   = module.vpc.vpc_id
  app_port = var.app_port
  tags     = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name                       = "${var.project}-${var.environment}"
  enable_github_actions_role = true
  aws_account_id             = var.aws_account_id
  github_repo                = var.github_repo
  secrets_arns               = [module.rds.credentials_secret_arn]
  tags                       = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name              = "${var.project}-${var.environment}"
  environment       = var.environment
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.rds_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  instance_class    = "db.t3.small"
  multi_az          = false
  tags              = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs-service"

  name               = "${var.project}-${var.environment}"
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  ecs_task_sg_id     = module.security_groups.ecs_task_sg_id
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  container_image    = var.container_image
  container_port     = var.app_port
  task_cpu           = 512
  task_memory        = 1024
  use_spot           = true
  desired_count      = 2
  min_capacity       = 2
  max_capacity       = 6

  secret_variables = [{
    name      = "DATABASE_URL"
    valueFrom = module.rds.credentials_secret_arn
  }]

  tags = local.common_tags
}
