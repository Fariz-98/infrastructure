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
      Env = "shared"
      Project = "tf-journal"
    }
  }
}

locals {
  name_prefix = "tf-journal-ecr"
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
        rulePriority = 10
        description = "Expire untagged images older than 7 days"
        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countNumber = 7
          countUnit = "days"
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 20
        description  = "Keep last 5 dev-* images"
        selection = {
          tagStatus      = "tagged"
          tagPrefixList  = ["dev-"]
          countType      = "imageCountMoreThan"
          countNumber    = 5
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 30
        description  = "Keep last 5 stg-* images"
        selection = {
          tagStatus      = "tagged"
          tagPrefixList  = ["stg-"]
          countType      = "imageCountMoreThan"
          countNumber    = 5
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 40
        description  = "Keep last 5 prod-* images"
        selection = {
          tagStatus      = "tagged"
          tagPrefixList  = ["prod-"]
          countType      = "imageCountMoreThan"
          countNumber    = 5
        }
        action = { type = "expire" }
      },
    ]
  })
}