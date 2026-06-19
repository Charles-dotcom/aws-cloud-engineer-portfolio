aws_region     = "us-east-1"
project        = "myapp"
environment    = "dev"
owner          = "platform-team"
cost_center    = "engineering"
aws_account_id = "123456789012"
github_repo    = "my-org/my-repo"

vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

app_port        = 8080
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp-dev:latest"

db_name = "appdb"
# db_username and db_password should be passed via TF_VAR_ env vars or CI secrets
# Never commit real credentials
