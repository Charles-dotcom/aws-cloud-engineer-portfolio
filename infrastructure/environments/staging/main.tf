module "workload" {
  source = "../../modules/workload"

  project                      = var.project
  environment                  = var.environment
  aws_region                   = var.aws_region
  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  public_subnet_cidrs          = var.public_subnet_cidrs
  private_subnet_cidrs         = var.private_subnet_cidrs
  single_nat_gateway           = var.single_nat_gateway
  enable_flow_logs             = var.enable_flow_logs
  flow_log_retention_days      = var.flow_log_retention_days
  container_image              = var.container_image
  container_port               = var.container_port
  task_cpu                     = var.task_cpu
  task_memory                  = var.task_memory
  desired_count                = var.desired_count
  min_capacity                 = var.min_capacity
  max_capacity                 = var.max_capacity
  use_spot                     = var.use_spot
  certificate_arn              = var.certificate_arn
  enable_alb_access_logs       = var.enable_alb_access_logs
  log_retention_days           = var.log_retention_days
  db_name                      = var.db_name
  db_username                  = var.db_username
  instance_class               = var.instance_class
  multi_az                     = var.multi_az
  backup_retention_days        = var.backup_retention_days
  deletion_protection          = var.deletion_protection
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  skip_final_snapshot          = var.skip_final_snapshot
  apply_immediately            = var.apply_immediately

  tags = {
    ManagedBy   = "Terraform"
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
}
