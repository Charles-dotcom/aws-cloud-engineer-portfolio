resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db"
  description = "Private subnets for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db"
  })
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-pg"
  family      = var.parameter_group_family
  description = "PostgreSQL parameters for ${var.name}"

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "immediate"
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.max_allocated_storage >= var.allocated_storage
      error_message = "max_allocated_storage must be at least allocated_storage."
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.name}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Dev stays single-AZ, without deletion protection and without enhanced
# monitoring, so a demonstration does not carry a production bill.
# The workload module refuses a production plan unless Multi-AZ and
# deletion protection are on.
resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_118:Enhanced monitoring is optional and is enabled by the production root
  #checkov:skip=CKV_AWS_157:Multi-AZ is optional and is required by the production guardrail
  #checkov:skip=CKV_AWS_293:Deletion protection is optional and is required by the production guardrail
  identifier = var.name

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_name  = var.db_name
  username = var.db_username

  # RDS generates the password and stores it in Secrets Manager.
  # The password is not a Terraform variable and is not written to this repo.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az            = var.multi_az
  publicly_accessible = false
  deletion_protection = var.deletion_protection

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final"
  copy_tags_to_snapshot     = true

  # 03:00 UTC is 05:00 SAST. 04:00 UTC is 06:00 SAST.
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = one(aws_iam_role.monitoring[*].arn)

  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  tags = var.tags
}
