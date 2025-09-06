terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  name_prefix = "tf-${var.env}-net"
  azs         = ["${var.region}a", "${var.region}b"]

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
      cidr = "10.0.21.0/24",
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

provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.name_prefix}-vpc"
    Env  = var.env
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# Subnet public
resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
  }
}

# Subnet private
resource "aws_subnet" "private" {
  for_each                = local.private_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
  tags = {
    Name = "${local.name_prefix}-private-${each.key}"
  }
}

# Route table - public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Route table - private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

# Associate public subnets with public rt
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

# Associate private subnets with private rt
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}

# SECURITY GROUPS (SG)
# SG - ALB
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Public ALB Ingress from internet"
  vpc_id      = aws_vpc.main.id

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
    Name = "${local.name_prefix}-alb-sg"
  }
}

# SG - App
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "For app (ecs in this case)"
  vpc_id      = aws_vpc.main.id

  # Only allow ALB to access (ingress)
  ingress {
    description     = "App port from ALB SG"
    from_port       = 8080
    protocol        = "tcp"
    to_port         = 8080
    security_groups = [aws_security_group.alb_sg.id] # Source via SG from alb-sg
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

# SG - VPC Endpoints
resource "aws_security_group" "vpce_sg" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "Allow HTTPS from app to interface (ENIs) VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  # App tasks to talk interface over 443
  ingress {
    description     = "HTTPS from app-sg"
    from_port       = 443
    protocol        = "tcp"
    to_port         = 443
    security_groups = [aws_security_group.app_sg.id]
  }

  # Endpoints dont initiate traffic, but SG needs it. Keep default
  egress {
    description = "Allow all egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-vpce-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${local.name_prefix}-db-sg"
  description = "RDS only from app-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "RDS from app-sg"
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-db-sg"
  }
}

# VPC Endpoints
# Gateway Endpoints
# S3
resource "aws_vpc_endpoint" "gateway" {
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"

  # private rt
  route_table_ids = [aws_route_table.private.id]

  # just in case access is permitted later
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*"
        Action    = ["s3:*"],
        Resource  = ["*"]
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-s3-gw"
  }
}

# Interface Endpoints
# ENI - ECR, ECS, Secrets, Logs
resource "aws_vpc_endpoint" "interfaces" {
  for_each = toset(local.interface_services)

  service_name      = each.value
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Interface"

  # Place in both private subnets
  subnet_ids = [for s in aws_subnet.private : s.id]

  # SG (only allow from app)
  security_group_ids = [aws_security_group.vpce_sg.id]

  # Resolve dns to private ip
  private_dns_enabled = true

  tags = {
    Name = "${local.name_prefix}-${replace(each.value, "com.amazonaws.${var.region}.", "")}"
  }
}























