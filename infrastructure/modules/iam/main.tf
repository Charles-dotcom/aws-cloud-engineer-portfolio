data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.name}-ecs-exec"
  description        = "Lets the ECS agent pull images, write logs and read the database secret."
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  statement {
    sid       = "ReadDatabaseSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secrets_arns
  }

  statement {
    sid       = "DecryptDatabaseSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  name   = "${var.name}-ecs-exec-secrets"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

# The application itself has no AWS permissions. Add a policy when a feature needs one.
resource "aws_iam_role" "ecs_task" {
  name               = "${var.name}-ecs-task"
  description        = "Runtime role for the application. Empty by default."
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json

  tags = var.tags
}
