output "alb_sg_id" {
  description = "ALB security group ID"
  value = aws_security_group.alb_sg.id
}

output "alb_arn" {
  description = "ALB ARN"
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value = aws_lb.this.dns_name
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value = one(aws_lb_listener.http[*].arn)
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value = one(aws_lb_listener.https[*].arn)
}

# Logs
output "log_bucket_name" {
  value = local.resolved_bucket_name
}

output "log_s3_prefix" {
  value = var.s3_log_prefix
}

output "alb_arn_suffix" {
  description = "ARN suffix needed for CloudWatch dimensions"
  value = aws_lb.this.arn_suffix
}