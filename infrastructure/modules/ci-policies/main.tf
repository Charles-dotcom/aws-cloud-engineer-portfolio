# Policy documents for the GitHub Actions plan and apply roles.
# ARNs that do not exist until apply are inputs, so a test can render the
# JSON with concrete values. Bootstrap attaches these documents to roles.
# See docs/adr/003-secrets-and-oidc.md.

locals {
  # IAM policy ARNs are deterministic: account, the policy/ prefix, and the name.
  permissions_boundary_arn = "arn:aws:iam::${var.account_id}:policy/${var.project}-workload-boundary"
}


data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:pull_request",
        "repo:${var.github_repository}:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  for_each = toset(var.apply_environments)

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:environment:${each.value}"]
    }
  }
}

data "aws_iam_policy_document" "deny_identity_creation" {
  statement {
    sid    = "DenyLongLivedIdentity"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:UpdateAccessKey",
      "iam:CreateLoginProfile",
      "organizations:LeaveOrganization",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "DenyCiRoleAndOidcChanges"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::${var.account_id}:role/${var.project}-gha-*",
      "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com",
    ]
  }

  statement {
    sid    = "DenyUnrelatedCompute"
    effect = "Deny"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateKeyPair",
      "ec2:ImportKeyPair",
      "ec2:CreateVolume",
      "ec2:AttachVolume",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "plan" {
  #checkov:skip=CKV_AWS_356:The read statement is Describe and List actions. Those actions do not support a resource-level permission.
  source_policy_documents = [data.aws_iam_policy_document.deny_identity_creation.json]

  statement {
    sid    = "ReadStateBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketLocation",
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }

  statement {
    sid    = "ReadStateObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/environments/*"]
  }

  statement {
    sid    = "StateLock"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.lock_table_name}"]
  }

  statement {
    sid    = "StateKey"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [var.state_kms_key_arn]
  }

  statement {
    sid    = "ReadThisStack"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "ecr:Describe*",
      "ecr:Get*",
      "ecr:List*",
      "rds:Describe*",
      "rds:List*",
      "logs:Describe*",
      "logs:List*",
      "iam:Get*",
      "iam:List*",
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
      "secretsmanager:Describe*",
      "secretsmanager:List*",
      "secretsmanager:GetResourcePolicy",
      "application-autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:List*",
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "workload_boundary" {
  #checkov:skip=CKV_AWS_356:GetAuthorizationToken and several log actions have no resource-level permission. The deny below is the ceiling on identity changes.
  #checkov:skip=CKV_AWS_111:The boundary is the maximum for task and monitoring roles. It is not an apply policy.
  #checkov:skip=CKV_AWS_108:The task role must read the database secret and decrypt it. This boundary is that ceiling, not an apply policy.
  statement {
    sid    = "TaskAndMonitoring"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DenyIdentity"
    effect    = "Deny"
    actions   = ["iam:*", "organizations:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "apply" {
  for_each = toset(var.apply_environments)

  #checkov:skip=CKV_AWS_356:Describe and List actions in the sourced plan policy have no resource-level permission. Writes below are named for this environment.
  source_policy_documents = [data.aws_iam_policy_document.plan.json]

  statement {
    sid    = "WriteOwnState"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/environments/${each.value}/*"]
  }

  statement {
    sid    = "EncryptOwnState"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
    ]
    resources = [var.state_kms_key_arn]
  }

  statement {
    sid    = "DenyStateKeyDeletion"
    effect = "Deny"
    actions = [
      "kms:ScheduleKeyDeletion",
      "kms:PutKeyPolicy",
      "kms:DisableKey",
      "kms:DeleteAlias",
    ]
    resources = [
      var.state_kms_key_arn,
      "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/${var.project}-tfstate",
    ]
  }

  statement {
    sid    = "ManageBucketsForThisEnvironment"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucket*",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:GetBucket*",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${var.project}-${each.value}-*",
      "arn:aws:s3:::${var.project}-${each.value}-*/*",
    ]
  }

  statement {
    sid    = "ManageNetworking"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:ModifySecurityGroupRules",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteVpcEndpoints",
      "ec2:ModifyVpcEndpoint",
      "ec2:CreateFlowLogs",
      "ec2:DeleteFlowLogs",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageWorkloadServices"
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:UpdateCluster",
      "ecs:PutClusterCapacityProviders",
      "ecs:CreateService",
      "ecs:UpdateService",
      "ecs:DeleteService",
      "ecs:TagResource",
      "ecs:UntagResource",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "rds:CreateDBInstance",
      "rds:DeleteDBInstance",
      "rds:ModifyDBInstance",
      "rds:CreateDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",
      "rds:CreateDBParameterGroup",
      "rds:DeleteDBParameterGroup",
      "rds:ModifyDBParameterGroup",
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource",
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot",
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:AssociateKmsKey",
      "logs:TagResource",
      "logs:UntagResource",
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:TagResource",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:TagResource",
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "kms:CreateKey",
      "kms:EnableKeyRotation",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:CreateAlias",
      "kms:DeleteAlias",
      "kms:UpdateAlias",
      "kms:CreateGrant",
      "kms:RevokeGrant",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:cluster/${var.project}-${each.value}-*",
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.project}-${each.value}-cluster/${var.project}-${each.value}",
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.project}-${each.value}:*",
      "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${var.project}-${each.value}",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:loadbalancer/app/${var.project}-${each.value}-alb/*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:targetgroup/${var.project}-${each.value}-tg/*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:listener/app/${var.project}-${each.value}-alb/*/*",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:db:${var.project}-${each.value}",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:subgrp:${var.project}-${each.value}-*",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:pg:${var.project}-${each.value}-*",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:snapshot:${var.project}-${each.value}-*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/ecs/${var.project}-${each.value}",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/ecs/${var.project}-${each.value}:*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/vpc/${var.project}-${each.value}*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/vpc/${var.project}-${each.value}*:*",
      "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:${var.project}-${each.value}-*",
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*",
      "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/${var.project}-${each.value}",
      "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:*",
      "arn:aws:application-autoscaling:${var.aws_region}:${var.account_id}:scalable-target/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = [each.value]
    }
  }

  # Create calls have no resource tag yet. Require the tag on the request,
  # and name the resource for this environment where the ARN includes the name.
  statement {
    sid    = "CreateWorkloadServices"
    effect = "Allow"
    actions = [
      "ecs:CreateCluster",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateService",
      "ecr:CreateRepository",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateListener",
      "rds:CreateDBInstance",
      "rds:CreateDBSubnetGroup",
      "rds:CreateDBParameterGroup",
      "logs:CreateLogGroup",
      "cloudwatch:PutMetricAlarm",
      "kms:CreateKey",
      "kms:CreateAlias",
      "kms:TagResource",
      "secretsmanager:CreateSecret",
      "application-autoscaling:RegisterScalableTarget",
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:cluster/${var.project}-${each.value}-*",
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.project}-${each.value}-cluster/${var.project}-${each.value}",
      "arn:aws:ecs:${var.aws_region}:${var.account_id}:task-definition/${var.project}-${each.value}:*",
      "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/${var.project}-${each.value}",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:loadbalancer/app/${var.project}-${each.value}-alb/*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:targetgroup/${var.project}-${each.value}-tg/*",
      "arn:aws:elasticloadbalancing:${var.aws_region}:${var.account_id}:listener/app/${var.project}-${each.value}-alb/*/*",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:db:${var.project}-${each.value}",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:subgrp:${var.project}-${each.value}-*",
      "arn:aws:rds:${var.aws_region}:${var.account_id}:pg:${var.project}-${each.value}-*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:*",
      "arn:aws:cloudwatch:${var.aws_region}:${var.account_id}:alarm:${var.project}-${each.value}-*",
      "arn:aws:kms:${var.aws_region}:${var.account_id}:key/*",
      "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/${var.project}-${each.value}",
      "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:*",
      "arn:aws:application-autoscaling:${var.aws_region}:${var.account_id}:scalable-target/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [each.value]
    }
  }

  # CreateKey has no key ARN yet, so it cannot be named. The request tag
  # keeps it in this environment. The state key is denied above.
  statement {
    sid       = "CreateKeyForThisEnvironment"
    effect    = "Allow"
    actions   = ["kms:CreateKey"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/Environment"
      values   = [each.value]
    }
  }

  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "CreateRolesForThisEnvironment"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
    ]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.project}-${each.value}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.permissions_boundary_arn]
    }
  }

  statement {
    sid    = "AttachKnownServicePolicies"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.project}-${each.value}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [local.permissions_boundary_arn]
    }

    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
        "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole",
      ]
    }
  }

  statement {
    sid       = "PassRolesThisEnvironment"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.project}-${each.value}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ecs-tasks.amazonaws.com",
        "monitoring.rds.amazonaws.com",
        "vpc-flow-logs.amazonaws.com",
      ]
    }
  }
}
