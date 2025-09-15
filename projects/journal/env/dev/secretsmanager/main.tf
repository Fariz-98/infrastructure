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
      Env = "dev"
      Project = "tf-journal"
      Name = "tf-journal"
    }
  }
}

locals {
  name = "/dev/tf-journal-2/app-config"
}

module "journal_secret" {
  source = "../../../../../modules/services/secretsmanager"

  name = name
  description = "App config for journal (dev)"
  recovery_window_in_days = 0
}