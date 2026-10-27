mock_provider "aws" {}

run "private_encrypted_managed_password" {
  command = plan

  variables {
    name              = "portfolio-dev"
    subnet_ids        = ["subnet-aaaa1111", "subnet-bbbb2222"]
    security_group_id = "sg-0123456789abcdef0"
    kms_key_arn       = "arn:aws:kms:af-south-1:000000000000:key/11111111-1111-1111-1111-111111111111"
    db_name           = "app"
    db_username       = "app"
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The database must not be publicly accessible."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "Storage must be encrypted."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "RDS must generate the master password."
  }

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == true
    error_message = "IAM database authentication should be available."
  }
}

run "rejects_reserved_username" {
  command = plan

  variables {
    name              = "portfolio-dev"
    subnet_ids        = ["subnet-aaaa1111", "subnet-bbbb2222"]
    security_group_id = "sg-0123456789abcdef0"
    kms_key_arn       = "arn:aws:kms:af-south-1:000000000000:key/11111111-1111-1111-1111-111111111111"
    db_name           = "app"
    db_username       = "postgres"
  }

  expect_failures = [var.db_username]
}
