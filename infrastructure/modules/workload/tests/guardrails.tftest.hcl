mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "000000000000"
    }
  }

  override_data {
    target = module.kms.data.aws_iam_policy_document.key
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.iam.data.aws_iam_policy_document.ecs_tasks_trust
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.iam.data.aws_iam_policy_document.execution_secrets[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "dev_plan_is_allowed" {
  command = plan

  variables {
    project                      = "portfolio"
    environment                  = "dev"
    aws_region                   = "af-south-1"
    vpc_cidr                     = "10.10.0.0/16"
    availability_zones           = ["af-south-1a", "af-south-1b"]
    public_subnet_cidrs          = ["10.10.0.0/24", "10.10.1.0/24"]
    private_subnet_cidrs         = ["10.10.10.0/24", "10.10.11.0/24"]
    single_nat_gateway           = true
    enable_flow_logs             = false
    flow_log_retention_days      = 14
    container_image              = "000000000000.dkr.ecr.af-south-1.amazonaws.com/portfolio-dev:1.0.0"
    task_cpu                     = 256
    task_memory                  = 512
    desired_count                = 1
    min_capacity                 = 1
    max_capacity                 = 2
    use_spot                     = true
    enable_alb_access_logs       = false
    log_retention_days           = 14
    db_name                      = "app"
    db_username                  = "app"
    instance_class               = "db.t3.micro"
    multi_az                     = false
    backup_retention_days        = 7
    deletion_protection          = false
    performance_insights_enabled = true
    monitoring_interval          = 0
    skip_final_snapshot          = true
    apply_immediately            = true
  }

  assert {
    condition     = output.ecs_cluster_name == "portfolio-dev-cluster"
    error_message = "Dev plan should create the portfolio-dev cluster."
  }
}

run "prod_without_multi_az_is_rejected" {
  command = plan

  variables {
    project                      = "portfolio"
    environment                  = "prod"
    aws_region                   = "af-south-1"
    vpc_cidr                     = "10.30.0.0/16"
    availability_zones           = ["af-south-1a", "af-south-1b", "af-south-1c"]
    public_subnet_cidrs          = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
    private_subnet_cidrs         = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
    single_nat_gateway           = false
    enable_flow_logs             = true
    flow_log_retention_days      = 90
    container_image              = "000000000000.dkr.ecr.af-south-1.amazonaws.com/portfolio-prod:1.0.0"
    task_cpu                     = 1024
    task_memory                  = 2048
    desired_count                = 3
    min_capacity                 = 3
    max_capacity                 = 6
    use_spot                     = false
    certificate_arn              = "arn:aws:acm:af-south-1:000000000000:certificate/11111111-1111-1111-1111-111111111111"
    enable_alb_access_logs       = true
    log_retention_days           = 90
    db_name                      = "app"
    db_username                  = "app"
    instance_class               = "db.t3.medium"
    multi_az                     = false
    backup_retention_days        = 14
    deletion_protection          = true
    performance_insights_enabled = true
    monitoring_interval          = 60
    skip_final_snapshot          = false
    apply_immediately            = false
  }

  expect_failures = [terraform_data.prod_guardrails]
}
