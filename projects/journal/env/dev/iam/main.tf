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

  default_tags {
    tags = {
      Env = var.env
      Project = "tf-journal"
    }
  }
}

locals {
  name_prefix = "tf-${var.env}-journal-iam"
  github_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  account_id = data.aws_caller_identity.current.account_id
}

# Policy for reading secrets
data "aws_iam_policy_document" "read_secrets" {
  statement {
    sid = "ReadAppSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn,
      "${data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn}-*",
    ]

    # Only allow if tag is dev (just in case)
    condition {
      test     = "StringEquals"
      values   = ["dev"]
      variable = "aws:ResourceTag/Env"
    }
  }

  # RDS Secret
  statement {
    sid = "ReadRdsMasterSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      data.terraform_remote_state.rds.outputs.rds_master_secret_arn
    ]
  }
}

resource "aws_iam_policy" "read_secrets" {
  name = "read-journal-secret"
  policy = data.aws_iam_policy_document.read_secrets.json
}

# Trust for ecs task execution
data "aws_iam_policy_document" "ecs_role_trust" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name               = "tf-journal-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_trust.json
  path               = "/service/"
  tags = {
    Project = "tf-journal"
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

# Attach read secrets to task role
resource "aws_iam_role_policy_attachment" "task_role_attach_read_secrets" {
  policy_arn = aws_iam_policy.read_secrets.arn
  role       = aws_iam_role.ecs_task.name
}

# ECS Execution Role
resource "aws_iam_role" "ecs_exec" {
  name               = "tf-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_trust.json
  tags = {
    Name = "${local.name_prefix}-ecs-exec-role"
  }
}

# Attach AWS-Managed policy for ECR execution role
resource "aws_iam_role_policy_attachment" "ecs_exec_managed" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_exec.name
}

# Attach read secrets to exec role
resource "aws_iam_role_policy_attachment" "ecs_exec_trust" {
  policy_arn = aws_iam_policy.read_secrets.arn
  role       = aws_iam_role.ecs_exec.name
}

# Trust Github Role for pipeline
data "aws_iam_policy_document" "gh_oidc_trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [local.github_oidc_provider_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    # Pin to environment
    condition {
      test     = "StringLike"
      values   = [
        "repo:Fariz-98/journal-backend:environment:dev",
        "repo:Fariz-98/journal-backend:ref:refs/heads/main"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role" "github_app_deploy" {
  name = "${local.name_prefix}-github-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.gh_oidc_trust.json
  tags = {
    Project = "Journal"
    Name = "${local.name_prefix}-github-app-deploy"
  }
}

# Policy to get ecr images, update ecs and rotate secrets
data "aws_iam_policy_document" "github_policy" {

  # ECR Auth
  statement {
    sid = "EcrAuth"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ECR Repo
  statement {
    sid = "EcrReadToGetImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:ListImages"
    ]
    resources = [
      data.terraform_remote_state.ecr.outputs.ecr_journal_repo_arn
    ]
  }

  # ECS
  statement {
    sid = "EcsDeploy"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeClusters"
    ]
    resources = ["*"]
  }

  # Allow pass role to ecs
  statement {
    sid = "AllowPassRolesToEcs"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_task.arn,
      aws_iam_role.ecs_exec.arn
    ]
    condition {
      test     = "StringEquals"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }

  statement {
    sid    = "GitHubRotateSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage"
    ]
    resources = [
      data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn,
      "${data.terraform_remote_state.secretsmanager.outputs.journal_secrets_arn}-*"
    ]
  }

  statement {
    sid = "ReadContracts"
    effect = "Allow"
    actions = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["*"]
  }
}

# Create policy
resource "aws_iam_policy" "github_deploy" {
  name = "GitHubDeploy"
  policy = data.aws_iam_policy_document.github_policy.json
}

# Attach policy to github role
resource "aws_iam_role_policy_attachment" "github_policy" {
  policy_arn = aws_iam_policy.github_deploy.arn
  role       = aws_iam_role.github_app_deploy.name
}