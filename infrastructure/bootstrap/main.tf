data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  state_bucket_name = "${var.project}-tfstate-${local.account_id}"
  lock_table_name   = "${var.project}-terraform-locks"
}

resource "terraform_data" "oidc_config" {
  lifecycle {
    precondition {
      condition     = var.create_oidc_provider || var.existing_oidc_provider_arn != ""
      error_message = "Set existing_oidc_provider_arn when create_oidc_provider is false."
    }
  }
}

module "kms" {
  source = "../modules/kms"

  name                    = "${var.project}-tfstate"
  description             = "Encrypts Terraform state and the lock table for ${var.project}."
  account_id              = local.account_id
  region                  = var.aws_region
  deletion_window_in_days = 30
  service_principals      = ["dynamodb.amazonaws.com"]
  prevent_destroy         = true
  tags = {
    Name = "${var.project}-tfstate"
  }
}

# The log bucket is the destination for state-bucket access logs.
# Cross-region replication and event notifications are left off.
resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_144:Cross-region replication of state access logs is a cost decision and is not enabled here
  #checkov:skip=CKV2_AWS_62:Event notifications are not required to retain state access logs
  bucket = "${var.project}-tfstate-logs-${local.account_id}"

  tags = {
    Name = "${var.project}-tfstate-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms.key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-access-logs"
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

data "aws_iam_policy_document" "logs" {
  statement {
    sid    = "AllowS3AccessLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
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
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_144:State is versioned and locked in one region. Cross-region replication is a cost decision and is not enabled here.
  #checkov:skip=CKV2_AWS_62:Event notifications are not required for a Terraform state bucket
  bucket = local.state_bucket_name

  tags = {
    Name = local.state_bucket_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms.key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "state" {
  bucket        = aws_s3_bucket.state.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "state/"
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "state" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json
}

resource "aws_dynamodb_table" "locks" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.kms.key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = true

  tags = {
    Name = local.lock_table_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS ignores this list for GitHub and trusts GitHub's published CAs
  # (GitHub changelog, 13 July 2023). The API still requires a value.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "${var.project}-github-oidc"
  }

  depends_on = [terraform_data.oidc_config]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}
