aws_region     = "us-east-1"
project        = "myapp"
environment    = "prod"
owner          = "platform-team"
cost_center    = "engineering"
compliance_tag = "SOC2"
aws_account_id = "123456789012"
github_repo    = "my-org/my-repo"

vpc_cidr             = "10.30.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]
private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]

app_port        = 8080
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp-prod:latest"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/REPLACE_ME"
db_name         = "appdb"
# db_username and db_password passed via CI secrets only — never committed
