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

variable "region" {
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

# Logs
variable "enable_log" {
  description = "Enable ALB access logging"
  type = bool
  default = true
}

variable "create_log_bucket" {
  description = "Create the S3 bucket for ALB logs"
  type = bool
  default = true
}

variable "manage_log_bucket_policy" {
  description = "If using an existing bucket, attach the necessary ELB writer policy to it"
  type = bool
  default = true
}

variable "existing_bucket_name" {
  description = "Name of an existing S3 bucket to store ALB, if create_bucket = false"
  type = string
  default = ""
}

variable "s3_log_prefix" {
  description = "S3 key prefix for ALB logs"
  type = string
  default = "alb"
}

variable "log_expiration_days" {
  description = "How many days to retain ALB logs"
  type = number
  default = 60
}

variable "log_force_destroy" {
  description = "Allow bucket to be destroyed even if not empty"
  type = bool
  default = false
}

variable "log_sse_algorithm" {
  description = "Server-side encryption algorithm, AES256 or aws:kms"
  type = string
  default = "AES256"
}

variable "log_kms_key_id" {
  type = string
  default = ""
}



















