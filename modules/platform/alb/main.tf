locals {
  # Logs
  # TODO: Bucket name is added with number suffix as the same name is unable to be reused for a specific amount of time
  resolved_bucket_name = var.create_log_bucket ? "tf-${var.env}-alb-logs-${data.aws_caller_identity.current.account_id}-5" : var.existing_bucket_name
  object_path_arn = "arn:aws:s3:::${local.resolved_bucket_name}/${var.s3_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/elasticloadbalancing/${var.region}/*"
}

resource "aws_security_group" "alb_sg" {
  name = "${var.name_prefix}-alb-sg"
  description = "Public ALB Ingress from the Internet"
  vpc_id = var.vpc_id

  # Dynamic for HTTP as we might add more cidr blocks later
  dynamic "ingress" {
    for_each = var.create_http_listener ? var.ingress_cidrs_http: []
    content {
      description = "HTTP from allowed CIDRs"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Dynamic for HTTPS as well, as we might add more cidr blocks later
  dynamic "ingress" {
    for_each = var.acm_certificate_arn != "" ? var.ingress_cidrs_https : []
    content {
      description = "HTTPS from allowed CIDRs"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    description = "Allow all egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_lb" "this" {
  name = var.name_prefix
  internal = false
  load_balancer_type = "application"
  subnets = var.public_subnet_ids
  security_groups = [aws_security_group.alb_sg.id]

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout = var.idle_timeout

  # Logs
  dynamic "access_logs" {
    for_each = var.enable_log ? [1] : []
    content {
      enabled = true
      bucket = local.resolved_bucket_name
      prefix = var.s3_log_prefix
    }
  }

  depends_on = [
    aws_s3_bucket_policy.log_writer
  ]

  tags = merge(var.tags, { Name = var.name_prefix })
}

resource "aws_lb_listener" "http" {
  count = var.create_http_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No service matched"
      status_code = "404"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-listener-80" })
}

resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No service matched"
      status_code = "404"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-listener-443" })
}

# Logs
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "this" {}

resource "aws_s3_bucket" "log" {
  count = var.enable_log && var.create_log_bucket ? 1 : 0
  bucket = local.resolved_bucket_name
  force_destroy = var.log_force_destroy

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = "tf-${var.env}-alb-logs" })
}

resource "aws_s3_bucket_public_access_block" "log" {
  count = var.enable_log && var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  count = var.enable_log && var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.log_sse_algorithm
      kms_master_key_id = var.log_sse_algorithm == "aws:kms" && length(var.log_kms_key_id) > 0 ? var.log_kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log" {
  count = var.enable_log && var.create_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log[0].id
  rule {
    id = "expire-alb-access-logs"
    status = "Enabled"

    filter {
      prefix = var.s3_log_prefix != "" ? var.s3_log_prefix : null
    }

    expiration {
      days = var.log_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "log_writer" {
  count = var.enable_log && (var.create_log_bucket || var.manage_log_bucket_policy) ? 1 : 0
  bucket = var.create_log_bucket ? aws_s3_bucket.log[0].id : local.resolved_bucket_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AWSLogDeliveryWrite",
        Effect: "Allow",
        Principal = { AWS = data.aws_elb_service_account.this.arn },
        Action = ["s3:PutObject"],
        Resource = local.object_path_arn
      },
      {
        Sid: "AwsLogDeliveryAclCheck",
        Effect: "Allow",
        Principal = { AWS = data.aws_elb_service_account.this.arn },
        Action = ["s3:GetBucketAcl"],
        Resource = "arn:aws:s3:::${local.resolved_bucket_name}"
      }
    ]
  })
}





















