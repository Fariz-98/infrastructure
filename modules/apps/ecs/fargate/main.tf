resource "aws_security_group" "app" {
  name = "${var.name_prefix}-sg"
  description = "ECS app SG"
  vpc_id = var.vpc_id

  ingress {
    description = "App port from ALB SG"
    from_port = var.container_port
    protocol  = "tcp"
    to_port   = var.container_port
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-sg"})
}

# App to VPCE (If enabled)
resource "aws_security_group_rule" "app_to_vpce" {
  count = var.enable_app_to_vpce && var.vpce_sg_id != null ? 1 : 0
  from_port         = 443
  protocol          = "tcp"
  security_group_id = var.vpce_sg_id
  to_port           = 443
  type              = "ingress"
  source_security_group_id = aws_security_group.app.id
  description = "Allow app to reach VPC Endpoints"
}

# App to RDS (If enabled)
resource "aws_security_group_rule" "app_to_rds" {
  count = var.enable_app_to_rds && var.rds_sg_id != null ? 1 : 0
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = var.rds_sg_id
  to_port           = 3306
  type              = "ingress"
  source_security_group_id = aws_security_group.app.id
  description = "Allow app to reach RDS"
}

# Logs
resource "aws_cloudwatch_log_group" "app" {
  name = var.log_group_name
  retention_in_days = var.log_retention_days
  tags = merge(var.tags, { Name = var.log_group_name })
}

# TG
resource "aws_lb_target_group" "app" {
  name = "${var.name_prefix}-tg"
  port = var.container_port
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  health_check {
    path                = var.hc_path
    matcher             = var.hc_matcher
    interval            = var.hc_interval
    healthy_threshold   = var.hc_healthy_threshold
    unhealthy_threshold = var.hc_unhealthy_threshold
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-tg" })
}

# Listener Rule
resource "aws_lb_listener_rule" "app" {
  listener_arn = var.alb_listener_arn
  priority = var.listener_rule_priority

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = var.listener_path_pattern
    }
  }
}

# Task def
resource "aws_ecs_task_definition" "app" {
  family = "${var.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = var.cpu
  memory = var.memory

  execution_role_arn = var.exec_role_arn
  task_role_arn = var.task_role_arn

  container_definitions = jsonencode([{
    name = var.container_name
    image = var.container_image
    essential = true
    portMappings = [{
      containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp"
    }]
    environment = var.env_variables
    secrets = var.secrets
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-region = var.region
        awslogs-group = aws_cloudwatch_log_group.app.name
        awslogs-stream-prefix = "app"
      }
    }
  }])

  tags = merge(var.tags, { Name = "${var.name_prefix}-taskdef" })
}

# Service
resource "aws_ecs_service" "app" {
  name = "${var.name_prefix}-svc"
  cluster = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = var.desired_count
  launch_type = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.app.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name = var.container_name
    container_port = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb_listener_rule.app]

  tags = merge(var.tags, { Name = "${var.name_prefix}-svc" })
}