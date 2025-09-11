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
  backend_app_name = "tf-journal-backend"
}

# Security Groups
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-sg"
  description = "For app (ecs in this case)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Only allow ALB to access (ingress)
  ingress {
    description     = "App port from ALB SG"
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
    security_groups = [data.terraform_remote_state.alb.outputs.alb_sg_id] # Source via SG from alb-sg
  }

  # Egress: allow all
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

# App -> VPCE
resource "aws_security_group_rule" "app_to_vpce" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = data.terraform_remote_state.vpc.outputs.vpce_sg_id
  source_security_group_id = aws_security_group.app_sg.id
  description = "Allow app to reach VPC Endpoints"
}

# App -> RDS
resource "aws_security_group_rule" "app_to_rds" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = data.terraform_remote_state.rds.outputs.rds_sg_id
  source_security_group_id = aws_security_group.app_sg.id
  to_port           = 3306
  type              = "ingress"
  description = "Allow app to reach RDS"
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "journal" {
  name = "/ecs/tf-journal-backend"
  retention_in_days = 5
  tags = {
    Project = "tf-journal",
    Env = "dev"
  }
}

# Target Group
resource "aws_lb_target_group" "journal" {
  name = "tf-journal-dev-tg"
  port = 8080
  protocol = "HTTP"
  target_type = "ip" # Fargate
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    path = "/" # TODO: Set up later in spring boot
    matcher = "200-399"
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  tags = {
    Project = "tf-journal"
    Name = "${local.name_prefix}-tg"
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "journal" {
  listener_arn = data.terraform_remote_state.alb.outputs.http_listener_arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.journal.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# App task definition
resource "aws_ecs_task_definition" "journal" {
  family = "tf-journal-task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "512"
  memory = "1024"

  execution_role_arn = data.terraform_remote_state.journal_iam.outputs.ecs_exec_role_arn
  task_role_arn = data.terraform_remote_state.journal_iam.outputs.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name = local.backend_app_name
      image = "TO_REPLACE_VIA_CICD"
      essential = true

      portMappings = [{
        containerPort = 8080, hostPort = 8080, protocol = "tcp"
      }]

      environment = [
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
    Name = "${local.name_prefix}-ecs-task-def"
  }
}

resource "aws_ecs_service" "journal" {
  name = "${local.name_prefix}-svc"
  cluster = data.terraform_remote_state.ecs.outputs.cluster_arn
  task_definition = aws_ecs_task_definition.journal.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.journal.arn
    container_name = "tf-journal-backend"
    container_port = 8080
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb_listener_rule.journal]

  tags = {
    Project = "tf-journal"
    Name = "${local.name_prefix}-ecs-service"
  }
}