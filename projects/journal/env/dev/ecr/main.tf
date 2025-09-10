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
  name_prefix = "tf-${var.env}-journal-ecr"
}

# app repo
resource "aws_ecr_repository" "journal" {
  name = "tf-journal-repo"
  image_tag_mutability = "IMMUTABLE"
  force_delete = true # Just for dev to tf destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project = "tf-journal"
    Name = local.name_prefix
  }
}

# Keep only latest 5 images
resource "aws_ecr_lifecycle_policy" "journal_cleanup" {
  repository = aws_ecr_repository.journal.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Keep last 5 images"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 5
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}