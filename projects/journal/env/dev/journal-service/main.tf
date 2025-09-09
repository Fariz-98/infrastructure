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
}

locals {
  name_prefix = "tf-${var.env}-net"
}

# Security Groups
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "For app (ecs in this case)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Only allow ALB to access (ingress)
  ingress {
    description     = "App port from ALB SG"
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
    security_groups = [data.terraform_remote_state.alb.outputs.id] # Source via SG from alb-sg
  }

  # Egress: allow all
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }
}

resource "aws_security_group_rule" "app_to_vpce" {
  type = "ingress"
  from_port = "443"
  to_port = "443"
  protocol = "tcp"
  security_group_id = data.terraform_remote_state.vpc.outputs.vpce_sg_id
  source_security_group_id = aws_security_group.app_sg.id
  description = "Allow app to reach VPC Endpoints"
}

resource "aws_security_group_rule" "app_to_rds" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = data.terraform_remote_state.rds.outputs.rds_sg_id
  to_port           = 3306
  type              = "ingress"
  description = "Allow app to reach RDS"
}

# ECS Task Definition
resource "aws_cloudwatch_log_group" "journal" {
  name = "/ecs/tf-journal-backend"
  retention_in_days = 5
  tags = {
    Project = "tf-journal",
    Env = "dev"
  }
}

resource "aws_ecs_cluster" "journal" {
  name = "tf-journal-cluster"
}

resource "aws_ecs_task_definition" "journal" {
  family = "tf-journal-task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "512"
  memory = "1024"

  execution_role_arn = data.terraform_remote_state.secrets.outputs.ecs_execution_role_arn
  task_role_arn = data.terraform_remote_state.secrets.outputs.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name = "tf-journal-backend"
      image = "TO_REPLACE_VIA_CICD"
      essential = true

      portMappings = [{
        containerPort = 8080, hostPort = 8080, protocol = "tcp"
      }]

      environment = [
        {
          name = "SPRING_DATASOURCE_URL", value = data.terraform_remote_state.rds.outputs.jdbc_url
        }
      ]

      secrets = [
        {
          name = "SPRING_DATASOURCE_USERNAME", valueFrom = "${data.terraform_remote_state.secrets.outputs.journal_secrets_arn}:dbUsername::"
        },
        {
          name = "SPRING_DATASOURCE_PASSWORD", valueFrom = "${data.terraform_remote_state.secrets.outputs.journal_secrets_arn}:dbPassword::"
        },
        {
          name = "APPLICATION_JWT_SECRETKEY", valueFrom = "${data.terraform_remote_state.secrets.outputs.journal_secrets_arn}:jwtSecret::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region = var.region
          awslogs-group = aws_cloudwatch_log_group.journal.name
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  tags = {
    Project = "tf-journal",
    Env = "dev"
  }
}