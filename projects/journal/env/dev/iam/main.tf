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
  github_role_name = "github-app-deploy"
  github_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  account_id = data.aws_caller_identity.current.account_id
}

# Inline Policy for reading secrets
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

# Trust for ECS
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
module "ecs_task" {
  source = "../../../../../modules/services/iam/role"

  name = "tf-journal-ecs-task-role"
  path = "/service/"

  trust_policy_json = data.aws_iam_policy_document.ecs_role_trust.json
  inline_policies = {
    "read_secrets-policy" = data.aws_iam_policy_document.read_secrets.json
  }

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

module "ecs_exec" {
  source = "../../../../../modules/services/iam/role"

  name = "tf-journal-ecs-exec-role"
  path = "/service/"

  trust_policy_json = data.aws_iam_policy_document.ecs_role_trust.json
  inline_policies = {
    "read_secrets-policy" = data.aws_iam_policy_document.read_secrets.json
  }
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]

  tags = {
    Name = "${local.name_prefix}-ecs-exec-role"
  }
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

# Github App Deploy inline policy to get ecr images, update ecs and rotate secrets
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
      module.ecs_exec.role_arn,
      module.ecs_task.role_arn
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
    actions = ["ssm:GetParameter", "ssm:PutParameter"]
    resources = ["*"]
  }
}

module "github_app_deploy" {
  source = "../../../../../modules/services/iam/role"

  name = "${local.name_prefix}-${local.github_role_name}"
  trust_policy_json = data.aws_iam_policy_document.gh_oidc_trust.json
  inline_policies = {
    "github-infra-policy" = data.aws_iam_policy_document.github_policy.json
  }

  tags = {
    Name = "${local.name_prefix}-${local.github_role_name}"
  }
}