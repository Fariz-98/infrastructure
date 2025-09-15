terraform {
  backend "local" {}
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data source = read-only lookup (who am I? used to build policies/tags if needed)
data "aws_caller_identity" "current" {}
# Exposes attributes like:
# data.aws_caller_identity.current.account_id
# (We’ll use it in the bucket policy so only *our* account can access.)

# S3 Bucket to hold state
resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket
  force_destroy = false

  tags = {
    Name = var.state_bucket
    Terraform = "true"
    Purpose = "remote-state"
  }
}

# Protect S3 bucket
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id # Attach to our bucket above
  block_public_acls = true  # Ignore any object ACLs that try to make it public
  block_public_policy = true # Block bucket policies that make it public
  ignore_public_acls = true # Treat any public ACLs as private
  restrict_public_buckets = true
}

# Versioning to keep track of state history (can roll back if needed)
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt object
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Force TLS + Limit to account
resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Deny non TLS traffic
      {
        Sid = "DenyNonTLS"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.tf_state.arn,
          "${aws_s3_bucket.tf_state.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = false }
        }
      },
    ]
  })
}

# DynamoDB table to coordinate lock
resource "aws_dynamodb_table" "tf_lock" {
  name = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.lock_table
    Terraform = true
    Purpose = "state-lock"
  }
}