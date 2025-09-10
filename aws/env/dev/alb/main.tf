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

# SG
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public ALB Ingress from internet"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # Ingress: Allow HTTP (80) and HTTPS (443) from all
  ingress {
    description = "HTTP from all"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from all"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: allow all
  egress {
    description = "Allow all egress"
    from_port   = 0
    protocol    = "-1" # -1 is all protocol
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

# LB itself
resource "aws_lb" "lb" {
  name = local.name_prefix
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = false # dev use for quick destroy
  idle_timeout = 60

  tags = {
    Name = local.name_prefix
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port = 80
  protocol = "HTTP"

  # Fixed response to 404 if there are no rule added
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No service matched"
      status_code = "404"
    }
  }

  tags = {
    Name = "${local.name_prefix}-listener"
  }
}

# HTTPS to be added later if needed