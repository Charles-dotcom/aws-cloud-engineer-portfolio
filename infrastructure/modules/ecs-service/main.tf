locals {
  # Pairs documented for the sizes this stack exposes. Reject anything else
  # rather than discover it at apply time.
  fargate_sizes = toset([
    "256/512", "256/1024", "256/2048",
    "512/1024", "512/2048", "512/3072", "512/4096",
    "1024/2048", "1024/3072", "1024/4096", "1024/8192",
    "2048/4096", "2048/8192", "2048/16384",
  ])

  health_command = [
    "CMD-SHELL",
    "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:${var.container_port}${var.health_check_path}')\" || exit 1",
  ]
}

resource "terraform_data" "fargate_size" {
  input = "${var.task_cpu}/${var.task_memory}"

  lifecycle {
    precondition {
      condition     = contains(local.fargate_sizes, "${var.task_cpu}/${var.task_memory}")
      error_message = "task_cpu and task_memory are not a supported Fargate pair. See the module variables."
    }

    precondition {
      condition     = var.min_capacity <= var.desired_count && var.desired_count <= var.max_capacity
      error_message = "min_capacity, desired_count and max_capacity are out of order."
    }
  }
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = var.use_spot ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
    base              = 0
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.container_image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = var.environment_variables
    secrets     = var.secret_variables

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }

    readonlyRootFilesystem = var.readonly_root_filesystem

    mountPoints = [{
      sourceVolume  = "tmp"
      containerPath = "/tmp"
      readOnly      = false
    }]

    linuxParameters = {
      initProcessEnabled = true
    }

    healthCheck = {
      command     = local.health_command
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = var.tags

  depends_on = [terraform_data.fargate_size]
}

# trivy:ignore:AVD-AWS-0053 This load balancer is the public entry point of the workload.
resource "aws_lb" "this" {
  #checkov:skip=CKV2_AWS_28:AWS WAF is a separate bill and is not part of this demonstration. Add it in front of production before real traffic.
  #checkov:skip=CKV2_AWS_20:The HTTP listener redirects to HTTPS when a certificate is set. Checkov reports this against the load balancer, and production refuses an empty certificate.
  name                       = "${var.name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  enable_http2               = true
  desync_mitigation_mode     = "defensive"
  idle_timeout               = 60

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []

    content {
      bucket  = aws_s3_bucket.access_logs[0].id
      prefix  = var.name
      enabled = true
    }
  }

  tags = var.tags
}

# This bucket holds the load balancer access logs. Logging it to itself
# would recurse, and cross-region replication plus event notifications
# would add cost without changing the demonstration.
resource "aws_s3_bucket" "access_logs" {
  #checkov:skip=CKV_AWS_18:This bucket is the access-log destination. It does not log to itself.
  #checkov:skip=CKV_AWS_144:Cross-region replication of access logs is a cost decision and is not enabled here
  #checkov:skip=CKV2_AWS_62:Event notifications are not required to retain access logs
  #checkov:skip=CKV_AWS_145:ALB access logs only support SSE-S3. A customer managed key makes enabling the logs fail. https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  count = var.enable_access_logs ? 1 : 0

  bucket = "${var.name}-alb-logs-${var.account_id}"

  tags = merge(var.tags, {
    Name = "${var.name}-alb-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.access_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# trivy:ignore:AVD-AWS-0132 ALB access logs only support SSE-S3. A customer managed key makes the load balancer refuse to enable logging. https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  #checkov:skip=CKV_AWS_145:ALB access logs only support SSE-S3. A customer managed key makes enabling the logs fail. https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  statement {
    sid    = "AllowELBLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    # The prefix must match aws_lb.access_logs.prefix. ELB checks this
    # policy when logging is turned on. SSE-S3 is the only encryption
    # ALB access logs accept.
    # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.access_logs[0].arn}/${var.name}/AWSLogs/${var.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:loadbalancer/*"]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.access_logs[0].arn,
      "${aws_s3_bucket.access_logs[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  count = var.enable_access_logs ? 1 : 0

  bucket = aws_s3_bucket.access_logs[0].id
  policy = data.aws_iam_policy_document.access_logs[0].json
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:TLS ends at the load balancer. Tasks speak HTTP on the application port inside the VPC.
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = var.tags
}

# With a certificate the listener redirects to HTTPS. Without one, which
# is the development default, it forwards so the stack can be planned
# before a certificate exists. Production refuses an empty certificate.
# trivy:ignore:AVD-AWS-0054
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_103:The HTTP listener redirects to TLS 1.2 or later once a certificate is set
  #checkov:skip=CKV2_AWS_20:The redirect is a dynamic action and is required in production
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [] : [1]

    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [1] : []

    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn == "" ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_service" "this" {
  name                   = var.name
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = var.use_spot ? null : "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = false

  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  propagate_tags                     = "SERVICE"

  dynamic "capacity_provider_strategy" {
    for_each = var.use_spot ? [1] : []

    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
      base              = 0
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_task_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = var.tags

  # Autoscaling owns the count after the first apply.
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx"
  alarm_description   = "Target 5xx responses from ${var.name}. See docs/sre/runbook-alb-5xx.md."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}
