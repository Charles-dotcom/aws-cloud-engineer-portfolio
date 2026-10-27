mock_provider "aws" {}

run "single_nat_for_two_zones" {
  command = plan

  variables {
    name                 = "portfolio-dev"
    cidr_block           = "10.10.0.0/16"
    availability_zones   = ["af-south-1a", "af-south-1b"]
    public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
    private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
    region               = "af-south-1"
    account_id           = "000000000000"
    single_nat_gateway   = true
    enable_flow_logs     = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "A single-NAT network must create one NAT gateway."
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected one public and one private subnet per zone."
  }

  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == false
    error_message = "Public subnets must not auto-assign public IPs."
  }
}

run "nat_per_zone" {
  command = plan

  variables {
    name                 = "portfolio-prod"
    cidr_block           = "10.30.0.0/16"
    availability_zones   = ["af-south-1a", "af-south-1b", "af-south-1c"]
    public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
    private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]
    region               = "af-south-1"
    account_id           = "000000000000"
    single_nat_gateway   = false
    enable_flow_logs     = true
    kms_key_arn          = "arn:aws:kms:af-south-1:000000000000:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_flow_log.this) == 1
    error_message = "Production shape needs one NAT gateway per zone and flow logs."
  }
}

run "rejects_a_bad_cidr" {
  command = plan

  variables {
    name                 = "portfolio-dev"
    cidr_block           = "not-a-cidr"
    availability_zones   = ["af-south-1a", "af-south-1b"]
    public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
    private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
    region               = "af-south-1"
    account_id           = "000000000000"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_uneven_subnets" {
  command = plan

  variables {
    name                 = "portfolio-dev"
    cidr_block           = "10.10.0.0/16"
    availability_zones   = ["af-south-1a", "af-south-1b"]
    public_subnet_cidrs  = ["10.10.0.0/24"]
    private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]
    region               = "af-south-1"
    account_id           = "000000000000"
  }

  expect_failures = [aws_vpc.this]
}
