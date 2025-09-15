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
  name_prefix = "tf-${var.env}-rds"
}

module "rds" {
  source = "../../../../modules/platform/rds"

  name_prefix = local.name_prefix
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  db_name = "dev_db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  max_allocated_storage = 0
  storage_type = "gp3"

  publicly_accessible = false
  backup_retention_period = 1
  delete_automated_backups = true
  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately = true

  multi_az = false
  performance_insights_enabled = false
  monitoring_interval = 0
}