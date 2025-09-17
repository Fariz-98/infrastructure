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
  name_prefix = "tf-${var.env}-ecs"
}

module "ecs_cluster" {
  source = "../../../../modules/platform/ecs"

  name_prefix = local.name_prefix
  env = var.env
  enable_container_insights = true
  enable_exec = true
  exec_log_retention_days = 3
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE",
      weight = 1,
      base = 0
    }
  ]

}