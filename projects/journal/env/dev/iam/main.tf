terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Policy for reading secrets
data "aws_iam_policy_document" "read_secrets" {
  statement {
    sid = "ReadAppSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn,
      "${data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn}*"
    ]

    # Only allow if tag is dev (just in case)
    condition {
      test     = "StringEquals"
      values   = ["dev"]
      variable = "aws:ResourceTag/Env"
    }
  }
}

resource "aws_iam_policy" "read_secrets" {
  name = "read-journal-secret"
  policy = data.aws_iam_policy_document.read_secrets.json
}

# Trust for ecs task execution
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

# ECS Execution Role
resource "aws_iam_role" "ecs_exec" {
  name               = "tf-journal-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
  path               = "/service/"
  tags = {
    Project = "tf-journal",
    Env     = "dev"
  }
}

# Attach AWS-Managed policy for ECR execution role
resource "aws_iam_role_policy_attachment" "ecs_exec_managed" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_exec.name
}

# Attach read secrets to execution role
resource "aws_iam_role_policy_attachment" "exec_role_attach_read_secrets" {
  policy_arn = aws_iam_policy.read_secrets.arn
  role       = aws_iam_role.ecs_exec.name
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name               = "tf-journal-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json
  path               = "/service/"
  tags = {
    Project = "tf-journal",
    Env     = "dev"
  }
}

# Attach read secrets to task role
resource "aws_iam_role_policy_attachment" "task_role_attach_read_secrets" {
  policy_arn = aws_iam_policy.read_secrets.arn
  role       = aws_iam_role.ecs_task.name
}