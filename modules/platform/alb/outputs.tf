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