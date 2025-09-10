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

resource "aws_security_group" "db_sg" {
  name        = "${local.name_prefix}-sg"
  description = "RDS SG"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  # For ingress, allow from whatever needs it
  egress {
    description = "Allow all egress"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg"
  }
}

resource "aws_db_subnet_group" "db_private_subnet" {
  name       = "tf-dev-db-subnets-matchbox3306"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  tags = {
    Name = "tf-dev-db-subnets-matchbox3306"
  }
}

resource "aws_db_instance" "rds" {
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  storage_type                = "gp3"
  username                    = "admin"
  manage_master_user_password = true
  db_name = "dev_db"
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.db_private_subnet.name
  publicly_accessible         = false
  backup_retention_period     = 1
  delete_automated_backups    = true
  skip_final_snapshot         = true
  apply_immediately           = true # Just for dev to reflect now as opposed to next maintenance window

  tags = {
    Name = "${local.name_prefix}-mysql"
  }
}