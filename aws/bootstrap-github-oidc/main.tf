terraform {
  backend "local" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Optional default tags
  default_tags {
    tags = {
      Env       = var.env
      Component = "bootstrap-github-oidc"
    }
  }
}

locals {
  apply_role_name      = "tf-${var.env}-github-oidc-deploy"
  apply_policy_name    = "tf-${var.env}-deploy-broad"

  plan_role_name = "tf-${var.env}-github-oidc-plan"
  plan_policy_name = "tf-${var.env}-plan-readonly"

  state_bucket   = data.terraform_remote_state.state.outputs.state_bucket_name
  state_prefix   = var.env
  ddb_lock_table = data.terraform_remote_state.state.outputs.dynamodb_lock_table
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e"
  ] # NOTE: Keep track if this changes
  url             = "https://token.actions.githubusercontent.com"
}

# TERRAFORM APPLY
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    # Limit to this repo and main branch
    condition {
      test     = "StringLike"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.branch}"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

# Role
resource "aws_iam_role" "deploy" {
  name               = local.apply_role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

# Broad permission policy (bootstrap)
data "aws_iam_policy_document" "policy" {
  statement {
    sid       = "StateS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]
  }

  statement {
    sid       = "StateS3Objects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/${local.state_prefix}*"]
  }

  statement {
    sid       = "StateLockDb"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem"]
    resources = ["arn:aws:dynamodb:${var.region}:${local.account_id}:table/${local.ddb_lock_table}"]
  }

  statement {
    sid    = "InfraBroad"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "ecs:*",
      "ecr:*",
      "logs:*",
      "secretsmanager:*",
      "rds:*",
      "route53:*",
      "ssm:*"
    ]
    resources = ["*"]
  }

  # For ecs task def
  statement {
    sid       = "PassRoleForEcs"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/*"]
    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }

  statement {
    sid    = "IamRole"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:CreatePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
      "iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListAttachedRolePolicies",
      "iam:DeletePolicy", "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "broad" {
  name   = local.apply_policy_name
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "attach_broad" {
  policy_arn = aws_iam_policy.broad.arn
  role       = aws_iam_role.deploy.name
}

# TERRAFORM PLAN
data "aws_iam_policy_document" "trust_plan" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [aws_iam_openid_connect_provider.github.arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }

    condition {
      test     = "StringLike"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:pull_request",
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/*"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

resource "aws_iam_role" "plan" {
  name = local.plan_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_plan.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    sid     = "StateBucketList"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${local.state_bucket}"
    ]
  }

  statement {
    sid     = "StateObjectsRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${local.state_bucket}/${local.state_prefix}*"
    ]
  }
}

data "aws_iam_policy_document" "plan_services" {
  statement {
    sid     = "Ec2Ro"
    effect  = "Allow"
    actions = [
      "ec2:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ElbRo"
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "EcsEcrRo"
    effect  = "Allow"
    actions = [
      "ecs:Describe*",
      "ecs:List*",
      "ecr:Describe*",
      "ecr:GetAuthorizationToken",
      "ecr:GetRegistryScanningConfiguration",
      "ecr:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "LogsRo"
    effect  = "Allow"
    actions = [
      "logs:Describe*",
      "logs:List*",
      "logs:GetLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "RdsRo"
    effect  = "Allow"
    actions = [
      "rds:Describe*",
      "rds:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "Route53Ro"
    effect  = "Allow"
    actions = [
      "route53:List*",
      "route53:TestDNSAnswer",
      "route53:GetHostedZone"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "SsmRo"
    effect  = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "IamRo"
    effect  = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "plan_state" {
  name   = "${local.plan_policy_name}-state"
  policy = data.aws_iam_policy_document.plan_state.json
}

resource "aws_iam_policy" "plan_services" {
  name   = "${local.plan_policy_name}-services"
  policy = data.aws_iam_policy_document.plan_services.json
}

resource "aws_iam_role_policy_attachment" "plan_attach_state" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_state.arn
}

resource "aws_iam_role_policy_attachment" "plan_attach_services" {
  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan_services.arn
}





























