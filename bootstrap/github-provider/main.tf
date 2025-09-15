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
      Component = "bootstrap-github-oidc"
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e"
  ] # NOTE: Keep track if this changes
  url             = "https://token.actions.githubusercontent.com"
}
