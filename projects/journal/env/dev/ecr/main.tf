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
    Env = "dev"
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