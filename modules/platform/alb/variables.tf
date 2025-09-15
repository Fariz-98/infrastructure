variable "name_prefix" {
  description = "Name prefix for ALB resources"
  type = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will live"
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type = list(string)
}

variable "env" {
  description = "Environment"
  type = string
}

variable "enable_deletion_protection" {
  description = "ALB deletion protection"
  type = bool
  default = false
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds"
  type = number
  default = 60
}

variable "ingress_cidrs_http" {
  description = "Allowed CIDRs for HTTP"
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "ingress_cidrs_https" {
  description = "Allowed CIDRs for HTTPS"
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "create_http_listener" {
  description = "Create HTTP listener"
  type = bool
  default = true
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN, if exist, module will create HTTPS listener"
  type = string
  default = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type = map(string)
  default = {}
}