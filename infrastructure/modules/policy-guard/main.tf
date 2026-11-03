terraform {
  required_version = ">= 1.9.0, < 2.0.0"
}

variable "documents" {
  description = "Policy JSON keyed by name."
  type        = map(string)
}

variable "limits" {
  description = "Non-whitespace character limit for each document."
  type        = map(number)
}

variable "resource_star_allowlist" {
  description = "Actions AWS authorizes only on Resource *."
  type        = list(string)
  default     = []
}

variable "require_environment_tag_deny" {
  description = "Documents that must deny a foreign Environment tag."
  type        = list(string)
  default     = []
}

locals {
  decoded = { for name, doc in var.documents : name => jsondecode(doc) }
  size = {
    for name, doc in var.documents :
    name => length(replace(replace(replace(replace(doc, " ", ""), "\n", ""), "\r", ""), "\t", ""))
  }
  statements = flatten([
    for name, doc in local.decoded : [
      for statement in doc.Statement : {
        name      = name
        effect    = statement.Effect
        actions   = try(tolist(statement.Action), [statement.Action])
        resources = try(tolist(statement.Resource), [statement.Resource], [])
        condition = try(statement.Condition, {})
      }
    ]
  ])
}

resource "terraform_data" "wildcard_action" {
  lifecycle {
    precondition {
      condition = alltrue([
        for statement in local.statements : statement.effect != "Allow" || alltrue([
          for action in statement.actions : action != "*" && !can(regex("^[a-z0-9-]+:\\*$", action))
        ])
      ])
      error_message = "An Allow uses * or service:*."
    }
  }
}

resource "terraform_data" "resource_star" {
  lifecycle {
    precondition {
      condition = alltrue([
        for statement in local.statements : statement.effect != "Allow" || !contains(statement.resources, "*") || alltrue([
          for action in statement.actions : contains(var.resource_star_allowlist, action)
        ])
      ])
      error_message = "An Allow uses Resource * for an action outside the no-resource-level allowlist."
    }
  }
}

resource "terraform_data" "document_size" {
  lifecycle {
    precondition {
      condition     = alltrue([for name, limit in var.limits : local.size[name] <= limit])
      error_message = "A policy document exceeds its size limit."
    }
  }
}

resource "terraform_data" "role_boundary" {
  lifecycle {
    precondition {
      condition = alltrue([
        for statement in local.statements : alltrue([
          for action in statement.actions : (
            statement.effect != "Allow" ||
            !can(regex("^iam:.*Role.*$", action)) ||
            can(regex("^iam:(Get|List|Describe)", action)) ||
            try(statement.condition.StringEquals["iam:PermissionsBoundary"], null) != null
          )
        ])
      ])
      error_message = "An iam:*Role* write is missing iam:PermissionsBoundary."
    }
  }
}

resource "terraform_data" "environment_tag_deny" {
  lifecycle {
    precondition {
      condition = alltrue([
        for name in var.require_environment_tag_deny : (
          anytrue([
            for statement in local.statements :
            statement.name == name && statement.effect == "Deny" && contains(statement.actions, "kms:TagResource") && contains(statement.actions, "kms:UntagResource") && try(statement.condition.StringNotEquals["aws:ResourceTag/Environment"], null) != null
            ]) && anytrue([
            for statement in local.statements :
            statement.name == name && statement.effect == "Deny" && contains(statement.actions, "ec2:CreateTags") && contains(statement.actions, "ec2:DeleteTags") && try(statement.condition.Null["ec2:CreateAction"], null) != null
          ])
        )
      ])
      error_message = "A required document is missing the Environment tag Deny."
    }
  }
}
