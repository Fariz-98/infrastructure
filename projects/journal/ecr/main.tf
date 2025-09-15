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

module "journal_ecr" {
  source = "../../../modules/services/ecr/repository"

  name_prefix = local.name_prefix
  force_delete = true

  lifecycle_policy = jsonencode({
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