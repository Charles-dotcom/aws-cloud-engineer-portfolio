run "accepts_a_scoped_policy" {
  command = plan
  variables {
    documents = { ok = jsonencode({
      Version = "2012-10-17"
      Statement = [
        { Effect = "Allow", Action = "ec2:Describe*", Resource = "*" },
        { Effect = "Allow", Action = "iam:PassRole", Resource = "arn:aws:iam::000000000000:role/example" },
        { Effect = "Deny", Action = ["kms:TagResource", "kms:UntagResource"], Resource = "*", Condition = { StringNotEquals = { "aws:ResourceTag/Environment" = "dev" } } },
        { Effect = "Deny", Action = ["ec2:CreateTags", "ec2:DeleteTags"], Resource = "*", Condition = { StringNotEquals = { "aws:ResourceTag/Environment" = "dev" }, Null = { "ec2:CreateAction" = "true" } } },
      ]
    }) }
    limits                       = { ok = 6144 }
    resource_star_allowlist      = ["ec2:Describe*"]
    require_environment_tag_deny = ["ok"]
  }
}

run "rejects_a_wildcard_action" {
  command = plan
  variables {
    documents               = { bad = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "s3:*", Resource = "arn:aws:s3:::example" }] }) }
    limits                  = { bad = 6144 }
    resource_star_allowlist = []
  }
  expect_failures = [terraform_data.wildcard_action]
}

run "rejects_a_resource_star" {
  command = plan
  variables {
    documents               = { bad = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "s3:GetObject", Resource = "*" }] }) }
    limits                  = { bad = 6144 }
    resource_star_allowlist = []
  }
  expect_failures = [terraform_data.resource_star]
}

run "rejects_an_oversized_document" {
  command = plan
  variables {
    documents               = { bad = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "ec2:Describe*", Resource = "*" }] }) }
    limits                  = { bad = 20 }
    resource_star_allowlist = ["ec2:Describe*"]
  }
  expect_failures = [terraform_data.document_size]
}

run "rejects_a_role_write_without_a_boundary" {
  command = plan
  variables {
    documents               = { bad = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "iam:CreateRole", Resource = "arn:aws:iam::000000000000:role/example" }] }) }
    limits                  = { bad = 6144 }
    resource_star_allowlist = []
  }
  expect_failures = [terraform_data.role_boundary]
}

run "rejects_a_missing_environment_tag_deny" {
  command = plan
  variables {
    documents                    = { bad = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "ec2:Describe*", Resource = "*" }] }) }
    limits                       = { bad = 6144 }
    resource_star_allowlist      = ["ec2:Describe*"]
    require_environment_tag_deny = ["bad"]
  }
  expect_failures = [terraform_data.environment_tag_deny]
}
