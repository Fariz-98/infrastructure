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

  # Optional default tags
  default_tags {
    tags = {
      Env       = var.env
    }
  }
}

locals {
  apply_role_name      = "tf-${var.env}-github-role-apply"
  plan_role_name = "tf-${var.env}-github-role-plan"

  oidc_host = "token.actions.githubusercontent.com"
  oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"

  state_bucket   = "dev-tf-state-bucket-matchbox3361"
  state_prefix   = var.env
  shared_prefix = "shared"
  ddb_lock_table = "dev-tf-state-lock"
  account_id = data.aws_caller_identity.current.account_id
}
# ---------------
# TERRAFORM APPLY
# ---------------
data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [local.oidc_provider_arn]
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

data "aws_iam_policy_document" "apply_policy" {
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
    resources = [
      "arn:aws:s3:::${local.state_bucket}/${local.state_prefix}/*",
      "arn:aws:s3:::${local.state_bucket}/${local.shared_prefix}/*" # For shared stuff
    ]
  }

  statement {
    sid = "S3AllowBucketManagement"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketOwnershipControls",
      "s3:PutBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketTagging",
      "s3:PutLifecycleConfiguration",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::tf-${var.env}-*"
    ]
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

  statement {
    sid       = "PassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/*"]
    condition {
      test     = "StringLike"
      values   = [
        "ecs-tasks.amazonaws.com",
        "vpc-flow-logs.amazonaws.com"
      ]
      variable = "iam:PassedToService"
    }
  }

  statement {
    sid    = "IamRole"
    effect = "Allow"
    actions = [
      # Roles
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListRoles", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",

      # Managed policies
      "iam:CreatePolicy", "iam:DeletePolicy",
      "iam:GetPolicy", "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion", "iam:DeletePolicyVersion", "iam:SetDefaultPolicyVersion",
      "iam:ListPolicies", "iam:ListPolicyVersions",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:TagPolicy", "iam:UntagPolicy", "iam:ListPolicyTags",

      # Inline role policies
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",

      # Instance profiles
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile", "iam:ListInstanceProfiles",
      "iam:ListInstanceProfilesForRole",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",

      # Service-linked roles
      "iam:CreateServiceLinkedRole", "iam:DeleteServiceLinkedRole",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowUseOfAWSManagedKMSKeys"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }
}

# --------------
# TERRAFORM PLAN
# --------------
data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [local.oidc_provider_arn]
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

data "aws_iam_policy_document" "plan_policy" {
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
      "arn:aws:s3:::${local.state_bucket}/${local.state_prefix}/*",
      "arn:aws:s3:::${local.state_bucket}/${local.shared_prefix}/*" # For shared stuff
    ]
  }

  statement {
    sid     = "Ec2Read"
    effect  = "Allow"
    actions = [
      "ec2:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ElbRead"
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "EcsEcrRead"
    effect  = "Allow"
    actions = [
      "ecs:Describe*",
      "ecs:List*",
      "ecr:Describe*",
      "ecr:GetAuthorizationToken",
      "ecr:GetRegistryScanningConfiguration",
      "ecr:List*",
      "ecr:GetLifecyclePolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "LogsRead"
    effect  = "Allow"
    actions = [
      "logs:Describe*",
      "logs:List*",
      "logs:GetLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "RdsRead"
    effect  = "Allow"
    actions = [
      "rds:Describe*",
      "rds:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "Route53Read"
    effect  = "Allow"
    actions = [
      "route53:List*",
      "route53:TestDNSAnswer",
      "route53:GetHostedZone"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "SsmRead"
    effect  = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "IamRead"
    effect  = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "SecretsManagerRead"
    effect  = "Allow"
    actions = [
      "secretsmanager:*"
    ]
    resources = ["*"]
  }
}

module "github_apply_role" {
  source = "../../../../../modules/services/iam/role"
  name = local.apply_role_name
  trust_policy_json = data.aws_iam_policy_document.apply_trust.json
  inline_policies = { "${var.env}-apply-policy" = data.aws_iam_policy_document.apply_policy.json }
  managed_policy_arns = []
}

module "github_plan_role" {
  source = "../../../../../modules/services/iam/role"
  name = local.plan_role_name
  trust_policy_json = data.aws_iam_policy_document.plan_trust.json
  inline_policies = { "${var.env}-plan-policy" = data.aws_iam_policy_document.plan_policy.json }
  managed_policy_arns = []
}