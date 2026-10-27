# Rules live in standalone resources so the load balancer can egress to the
# tasks and the tasks can egress to the database without a dependency cycle.
# aws_security_group removes the default allow-all egress when no inline
# egress block is set.

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:Attached by the ECS module through the alb security group output
  name        = "${var.name}-alb"
  description = "Public entry to the load balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_task" {
  #checkov:skip=CKV2_AWS_5:Attached by the ECS service through the task security group output
  name        = "${var.name}-tasks"
  description = "Application tasks. Ingress only from the load balancer."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-tasks"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  #checkov:skip=CKV2_AWS_5:Attached by the RDS module through the database security group output
  name        = "${var.name}-rds"
  description = "PostgreSQL. Ingress only from application tasks."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-rds"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Port 80 stays open so the listener can redirect clients to HTTPS
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from clients, redirected to HTTPS when a certificate is set"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = var.alb_ingress_cidr
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from clients"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.alb_ingress_cidr
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Application port on the tasks"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.ecs_task.id
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.ecs_task.id
  description                  = "Application port from the load balancer"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

# trivy:ignore:AVD-AWS-0104 Tasks reach ECR, CloudWatch Logs and Secrets Manager through the NAT gateway. Interface endpoints were left out because each one is billed per hour per zone.
resource "aws_vpc_security_group_egress_rule" "tasks_https" {
  security_group_id = aws_security_group.ecs_task.id
  description       = "HTTPS to AWS APIs through the NAT gateway"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "tasks_to_rds" {
  security_group_id            = aws_security_group.ecs_task.id
  description                  = "PostgreSQL on RDS"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_tasks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from application tasks"
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.ecs_task.id
}
