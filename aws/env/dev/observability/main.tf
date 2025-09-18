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
    }
  }
}

locals {
  name_prefix = "tf-${var.env}-alerts"
}

module "alerts" {
  source = "../../../../modules/platform/observability/alerts"

  alert_emails = var.alert_emails
  topic_name = local.name_prefix
}