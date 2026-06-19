aws_region     = "us-east-1"
project        = "myapp"
environment    = "staging"
owner          = "platform-team"
cost_center    = "engineering"
aws_account_id = "123456789012"
github_repo    = "my-org/my-repo"

vpc_cidr             = "10.20.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

app_port        = 8080
container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp-staging:latest"
db_name         = "appdb"
