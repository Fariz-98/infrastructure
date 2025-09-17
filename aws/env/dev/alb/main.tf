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
  name_prefix = "tf-${var.env}-alb"
}

module "alb" {
  source = "../../../../modules/platform/alb"

  name_prefix = local.name_prefix
  env = var.env
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = false
  idle_timeout = 60
  create_http_listener = true

  acm_certificate_arn = ""

  ingress_cidrs_http = ["0.0.0.0/0"]
  ingress_cidrs_https = ["0.0.0.0/0"]

  # Access Logs
  enable_log = true
  create_log_bucket = true
  manage_log_bucket_policy = true
  log_force_destroy = true
  existing_bucket_name = ""
  region = var.region
  s3_log_prefix = "alb"
  log_expiration_days = 60
  log_sse_algorithm = "AES256"
  log_kms_key_id = ""
}