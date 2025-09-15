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
  name_prefix = "tf-${var.env}-net"

  # Subnets map
  public_subnets = {
    a = {
      cidr = "10.0.1.0/24",
      az   = "${var.region}a"
    }
    b = {
      cidr = "10.0.2.0/24",
      az   = "${var.region}b"
    }
  }

  private_subnets = {
    a = {
      cidr = "10.0.11.0/24",
      az   = "${var.region}a"
    }
    b = {
      cidr = "10.0.12.0/24",
      az   = "${var.region}b"
    }
  }

  # VPC Endpoints
  interface_services = [
    "com.amazonaws.${var.region}.ecr.api",
    "com.amazonaws.${var.region}.ecr.dkr",
    # "com.amazonaws.${var.region}.ecs", not needed for fargate
    # "com.amazonaws.${var.region}.ecs-agent", not needed for fargate
    # "com.amazonaws.${var.region}.ecs-telemetry", not needed for fargate
    "com.amazonaws.${var.region}.secretsmanager",
    "com.amazonaws.${var.region}.logs"
  ]
}

module "vpc" {
  source = "../../../../modules/platform/vpc"

  name_prefix = local.name_prefix
  region = var.region

  vpc_cidr = var.vpc_cidr
  public_subnets = local.public_subnets
  private_subnets = local.private_subnets
  interface_services = local.interface_services
  create_s3_gateway_endpoint = true
}