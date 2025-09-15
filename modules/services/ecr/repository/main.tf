resource "aws_ecr_repository" "this" {
  name = var.name_prefix
  image_tag_mutability = var.image_tag_mutability
  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key = var.encryption_type == "KMS" ? var.kms_key : null
  }

  tags = merge(var.tags, { Name = var.name_prefix })
}

resource "aws_ecr_lifecycle_policy" "this" {
  policy     = var.lifecycle_policy
  repository = aws_ecr_repository.this.name
  count = var.lifecycle_policy != null ? 1 : 0
}