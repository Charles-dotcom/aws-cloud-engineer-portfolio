data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  name       = "${var.project}-${var.environment}"
}

resource "terraform_data" "prod_guardrails" {
  input = var.environment

  lifecycle {
    precondition {
      condition = (
        var.environment != "prod" ||
        (
          var.multi_az &&
          var.deletion_protection &&
          var.single_nat_gateway == false &&
          var.certificate_arn != "" &&
          var.use_spot == false &&
          var.enable_alb_access_logs &&
          var.skip_final_snapshot == false &&
          length(var.availability_zones) >= 3
        )
      )
      error_message = "Production must use three zones, a NAT gateway per zone, Multi-AZ RDS, deletion protection, a final snapshot, ALB access logs, an ACM certificate and on-demand Fargate."
    }
  }
}

module "kms" {
  source = "../kms"

  name                    = local.name
  description             = "Encrypts ${local.name} data, logs and secrets."
  account_id              = local.account_id
  region                  = var.aws_region
  deletion_window_in_days = var.environment == "prod" ? 30 : 7
  service_principals = [
    "rds.amazonaws.com",
    "secretsmanager.amazonaws.com",
    "ecr.amazonaws.com",
  ]
  tags = var.tags
}

module "vpc" {
  source = "../vpc"

  name                    = local.name
  cidr_block              = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  region                  = var.aws_region
  account_id              = local.account_id
  single_nat_gateway      = var.single_nat_gateway
  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.flow_log_retention_days
  kms_key_arn             = module.kms.key_arn
  tags                    = var.tags
}

module "security_groups" {
  source = "../security-groups"

  name     = local.name
  vpc_id   = module.vpc.vpc_id
  app_port = var.container_port
  tags     = var.tags
}

module "rds" {
  source = "../rds"

  name                         = local.name
  subnet_ids                   = module.vpc.private_subnet_ids
  security_group_id            = module.security_groups.rds_sg_id
  kms_key_arn                  = module.kms.key_arn
  db_name                      = var.db_name
  db_username                  = var.db_username
  instance_class               = var.instance_class
  multi_az                     = var.multi_az
  backup_retention_days        = var.backup_retention_days
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  apply_immediately            = var.apply_immediately
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  tags                         = var.tags

  depends_on = [terraform_data.prod_guardrails]
}

module "iam" {
  source = "../iam"

  name         = local.name
  region       = var.aws_region
  secrets_arns = [module.rds.credentials_secret_arn]
  kms_key_arn  = module.kms.key_arn
  tags         = var.tags
}

module "ecs" {
  source = "../ecs-service"

  name                = local.name
  region              = var.aws_region
  account_id          = local.account_id
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  alb_sg_id           = module.security_groups.alb_sg_id
  ecs_task_sg_id      = module.security_groups.ecs_task_sg_id
  execution_role_arn  = module.iam.ecs_task_execution_role_arn
  task_role_arn       = module.iam.ecs_task_role_arn
  kms_key_arn         = module.kms.key_arn
  container_image     = var.container_image
  container_port      = var.container_port
  task_cpu            = var.task_cpu
  task_memory         = var.task_memory
  desired_count       = var.desired_count
  min_capacity        = var.min_capacity
  max_capacity        = var.max_capacity
  use_spot            = var.use_spot
  certificate_arn     = var.certificate_arn
  enable_access_logs  = var.enable_alb_access_logs
  deletion_protection = var.deletion_protection
  log_retention_days  = var.log_retention_days

  environment_variables = [
    {
      name  = "DB_HOST"
      value = module.rds.db_address
    },
    {
      name  = "DB_PORT"
      value = tostring(module.rds.db_port)
    },
    {
      name  = "DB_NAME"
      value = var.db_name
    },
    {
      name  = "DB_SSLMODE"
      value = "require"
    },
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
  ]

  secret_variables = [
    {
      name      = "DB_USERNAME"
      valueFrom = "${module.rds.credentials_secret_arn}:username::"
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = "${module.rds.credentials_secret_arn}:password::"
    },
  ]

  tags = var.tags
}
