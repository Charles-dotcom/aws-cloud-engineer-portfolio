provider "aws" {
  region = "af-south-1"

  # The documents are computed locally. These skips keep the test from calling STS.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

run "dev_apply_is_scoped" {
  command = plan

  variables {
    account_id        = "000000000000"
    aws_region        = "af-south-1"
    project           = "portfolio"
    github_repository = "Charles-dotcom/aws-cloud-engineer-portfolio"
    # 12-digit account id and a 36-character key id. Both lengths are fixed,
    # so this render is the same size as a real account.
    apply_environments = ["dev", "staging", "prod"]
    state_bucket_name  = "portfolio-tfstate-000000000000"
    lock_table_name    = "portfolio-terraform-locks"
    state_kms_key_arn  = "arn:aws:kms:af-south-1:000000000000:key/11111111-1111-1111-1111-111111111111"
    oidc_provider_arn  = "arn:aws:iam::000000000000:oidc-provider/token.actions.githubusercontent.com"
  }

  assert {
    condition     = length(regexall("s3:PutObject|s3:DeleteObject", data.aws_iam_policy_document.plan.json)) == 0
    error_message = "The plan role must not write or delete state objects."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.plan.json, "dynamodb:PutItem")
    error_message = "The plan role still needs to write the lock table."
  }

  assert {
    condition     = !strcontains(data.aws_iam_policy_document.apply["dev"].json, "portfolio-prod")
    error_message = "The dev apply policy must not name prod resources."
  }

  assert {
    condition     = !strcontains(data.aws_iam_policy_document.apply["dev"].json, "environments/prod/")
    error_message = "The dev apply role must not write the prod state prefix."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.apply["dev"].json, "environments/dev/")
    error_message = "The dev apply role must write only its own state prefix."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.apply["prod"].json, "portfolio-prod") && strcontains(data.aws_iam_policy_document.apply["prod"].json, "environments/prod/")
    error_message = "The prod apply policy must name its own resources, so the dev assertion is not an empty match."
  }

  assert {
    condition     = !strcontains(data.aws_iam_policy_document.apply["dev"].json, "OpenIDConnectProvider")
    error_message = "Apply must not manage the GitHub OIDC provider."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.apply["dev"].json, "DenyCiRoleAndOidcChanges")
    error_message = "Apply must deny changes to the CI roles and the OIDC provider."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.apply["dev"].json, "arn:aws:iam::000000000000:role/portfolio-gha-*")
    error_message = "The deny must name the CI roles."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(data.aws_iam_policy_document.apply["dev"].json).Statement :
      statement.Effect != "Allow" || !anytrue([
        for action in try(tolist(statement.Action), [statement.Action]) :
        contains([
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
        ], action)
        ]) || (
        try(statement.Condition.StringEquals["iam:PermissionsBoundary"], null) != null
        && alltrue([
          for resource in try(tolist(statement.Resource), [statement.Resource]) :
          !strcontains(resource, ":role/portfolio-gha-")
        ])
      )
    ])
    error_message = "IAM writes must require the permissions boundary and must not target the CI roles."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(data.aws_iam_policy_document.apply["dev"].json).Statement :
      statement.Effect != "Allow" || !contains(try(tolist(statement.Action), [statement.Action]), "iam:AttachRolePolicy") || (
        try(statement.Condition.ArnEquals["iam:PolicyARN"], null) != null
        && alltrue([
          for arn in try(tolist(statement.Condition.ArnEquals["iam:PolicyARN"]), [statement.Condition.ArnEquals["iam:PolicyARN"]]) :
          contains([
            "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
            "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole",
          ], arn)
        ])
      )
    ])
    error_message = "AttachRolePolicy may only attach the ECS execution policy and the RDS monitoring policy."
  }

  assert {
    condition = alltrue([
      for env in ["dev", "staging", "prod"] : anytrue([
        for statement in jsondecode(data.aws_iam_policy_document.apply[env].json).Statement :
        statement.Sid == "DenyForeignKmsEnvironmentTag"
        && statement.Effect == "Deny"
        && toset(try(tolist(statement.Action), [statement.Action])) == toset(["kms:TagResource", "kms:UntagResource"])
        && try(tolist(statement.Condition.StringNotEquals["aws:ResourceTag/Environment"]), [statement.Condition.StringNotEquals["aws:ResourceTag/Environment"]]) == [env]
        && contains(try(tolist(statement.Condition["ForAnyValue:StringEquals"]["aws:TagKeys"]), [statement.Condition["ForAnyValue:StringEquals"]["aws:TagKeys"]]), "Environment")
        ]) && anytrue([
        for statement in jsondecode(data.aws_iam_policy_document.apply[env].json).Statement :
        statement.Sid == "DenyForeignEc2EnvironmentTag"
        && statement.Effect == "Deny"
        && toset(try(tolist(statement.Action), [statement.Action])) == toset(["ec2:CreateTags", "ec2:DeleteTags"])
        && try(tolist(statement.Condition.StringNotEquals["aws:ResourceTag/Environment"]), [statement.Condition.StringNotEquals["aws:ResourceTag/Environment"]]) == [env]
        && try(tolist(statement.Condition.Null["ec2:CreateAction"]), [statement.Condition.Null["ec2:CreateAction"]]) == ["true"]
      ])
    ])
    error_message = "Apply must deny Environment tag changes on another environment's KMS key, and on an EC2 resource that already exists."
  }

  assert {
    condition = alltrue([
      for statement in jsondecode(data.aws_iam_policy_document.apply["dev"].json).Statement :
      statement.Effect != "Allow" || alltrue([
        for action in try(tolist(statement.Action), [statement.Action]) :
        !strcontains(action, "ec2:") || strcontains(action, "ec2:Describe") || contains(output.ec2_actions_without_resource_permissions, action) || try(statement.Condition.StringEquals["aws:RequestTag/Environment"], null) != null || try(statement.Condition.StringEquals["aws:ResourceTag/Environment"], null) != null
      ])
    ])
    error_message = "The dev policy has an EC2 write with no Environment condition outside the no-resource-level allowlist."
  }

  assert {
    condition = alltrue([
      for env in ["dev", "staging", "prod"] :
      length(output.apply_managed_policies[env]) <= 10 && alltrue([
        for group, doc in output.apply_managed_policies[env] :
        length(replace(replace(replace(replace(doc, " ", ""), "\n", ""), "\r", ""), "\t", "")) <= 6144
      ])
    ])
    error_message = "Each apply role needs at most 10 managed policies, each at most 6144 characters with whitespace removed. ${jsonencode(output.policy_character_counts)}"
  }

  assert {
    condition = (
      output.policy_character_counts["plan"] <= 10240
      && output.policy_character_counts["plan_trust"] <= 10240
      && output.policy_character_counts["boundary"] <= 6144
      && alltrue([
        for env in ["dev", "staging", "prod"] :
        output.policy_character_counts["apply_trust/${env}"] <= 10240
      ])
    )
    error_message = "An inline policy must stay under 10240 characters and the boundary under 6144. ${jsonencode(output.policy_character_counts)}"
  }
}
