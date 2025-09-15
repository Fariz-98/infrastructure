resource "aws_security_group" "alb_sg" {
  name = "${var.name_prefix}-alb-sg"
  description = "Public ALB Ingress from the Internet"
  vpc_id = var.vpc_id

  # Dynamic for HTTP as we might add more cidr blocks later
  dynamic "ingress" {
    for_each = var.create_http_listener ? var.ingress_cidrs_http: []
    content {
      description = "HTTP from allowed CIDRs"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Dynamic for HTTPS as well, as we might add more cidr blocks later
  dynamic "ingress" {
    for_each = var.acm_certificate_arn != "" ? var.ingress_cidrs_https : []
    content {
      description = "HTTPS from allowed CIDRs"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_lb" "this" {
  name = var.name_prefix
  internal = false
  load_balancer_type = "application"
  subnets = var.public_subnet_ids
  security_groups = [aws_security_group.alb_sg.id]

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout = var.idle_timeout

  tags = merge(var.tags, { Name = var.name_prefix })
}

resource "aws_lb_listener" "http" {
  count = var.create_http_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No service matched"
      status_code = "404"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-listener-80" })
}

resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No service matched"
      status_code = "404"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-listener-443" })
}