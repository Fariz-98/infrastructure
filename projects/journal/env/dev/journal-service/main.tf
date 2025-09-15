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
  name_prefix = "tf-${var.env}-journal-app"
  app_container_name = "tf-journal-backend"
}

module "journal_service" {
  source = "../../../../../modules/apps/ecs/fargate"

  name_prefix = local.name_prefix
  region = var.region

  # VPC
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  # ALB
  alb_sg_id = data.terraform_remote_state.alb.outputs.alb_sg_id
  alb_listener_arn = data.terraform_remote_state.alb.outputs.http_listener_arn
  listener_rule_priority = 100
  listener_path_pattern = ["/api/*"]

  # SG
  enable_app_to_rds = true
  rds_sg_id = data.terraform_remote_state.rds.outputs.rds_sg_id

  enable_app_to_vpce = true
  vpce_sg_id = data.terraform_remote_state.vpc.outputs.vpce_sg_id

  # ECS Task Def
  container_name = local.app_container_name
  cpu = "512"
  memory = "1024"
  task_role_arn = data.terraform_remote_state.journal_iam.outputs.ecs_task_role_arn
  exec_role_arn = data.terraform_remote_state.journal_iam.outputs.ecs_exec_role_arn
  container_port = 8080
  env_variables = [
    {
      name = "SPRING_DATASOURCE_URL",
      value = "jdbc:mysql://${data.terraform_remote_state.rds.outputs.endpoint}/${data.terraform_remote_state.rds.outputs.rds_db_name}?serverTimezone=UTC"
    }
  ]
  secrets = [
    {
      name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${data.terraform_remote_state.rds.outputs.rds_master_secret_arn}:username::"
    },
    {
      name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${data.terraform_remote_state.rds.outputs.rds_master_secret_arn}:password::"
    },
    {
      name = "APPLICATION_JWT_SECRETKEY", valueFrom = "${data.terraform_remote_state.secrets.outputs.journal_secrets_arn}:jwtSecret::"
    }
  ]
  log_group_name = "/ecs/${local.name_prefix}"
  log_retention_days = 5

  # ECS Service
  cluster_arn = data.terraform_remote_state.ecs.outputs.cluster_arn
  desired_count = 1
  assign_public_ip = false
}