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

resource "aws_secretsmanager_secret" "secrets" {
  name                    = "/dev/tf-journal/app-config"
  recovery_window_in_days = 7
  tags = {
    Project = "tf-journal",
    Env     = "dev"
  }
}