mock_provider "aws" {}

run "database_is_only_reachable_from_tasks" {
  command = plan

  variables {
    name   = "portfolio-dev"
    vpc_id = "vpc-0123456789abcdef0"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_tasks.from_port == 5432 && aws_vpc_security_group_ingress_rule.rds_from_tasks.to_port == 5432
    error_message = "RDS ingress must be PostgreSQL."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.alb_to_tasks.from_port == 8080 && aws_vpc_security_group_ingress_rule.tasks_from_alb.from_port == 8080
    error_message = "The load balancer and the tasks must meet on the application port."
  }

  assert {
    condition     = aws_vpc_security_group_egress_rule.tasks_https.from_port == 443
    error_message = "Task egress to AWS APIs must be HTTPS only."
  }

  assert {
    condition = alltrue([
      for port in [
        aws_vpc_security_group_ingress_rule.alb_http.from_port,
        aws_vpc_security_group_ingress_rule.alb_https.from_port,
        aws_vpc_security_group_ingress_rule.tasks_from_alb.from_port,
        aws_vpc_security_group_ingress_rule.rds_from_tasks.from_port,
      ] : port != 22
    ])
    error_message = "SSH must not be opened."
  }
}
