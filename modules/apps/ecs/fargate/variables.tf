variable "name_prefix" {
  description = "Prefix for resource name"
  type = string
}
variable "region" {
  type = string
}

# VPC
variable "vpc_id" {
  description = "VPC ID for the resource to live in"
  type = string
}
variable "private_subnet_ids" {
  description = "Private subnets for the resource"
  type = list(string)
}

# ALB
variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type = string
}
variable "alb_listener_arn" {
  description = "ALB Listener ARN"
  type = string
}
variable "listener_rule_priority" {
  type = number
}
variable "listener_path_pattern" {
  type = list(string)
  default = []
}

# TG
variable "hc_path" {
  type = string
  default = "/"
}
variable "hc_matcher" {
  type = string
  default = "200-399"
}
variable "hc_interval" {
  type = number
  default = 30
}
variable "hc_healthy_threshold" {
  type = number
  default = 2
}
variable "hc_unhealthy_threshold" {
  type = number
  default = 2
}

# SGs
variable "enable_app_to_rds" {
  type = bool
  default = true
}
variable "rds_sg_id" {
  type = string
  default = null
}

variable "enable_app_to_vpce" {
  type = bool
  default = true
}
variable "vpce_sg_id" {
  type = string
  default = null
}

# ECS Task Def
variable "container_name" {
  type = string
}
variable "cpu" {
  type = string
  default = "512"
}
variable "memory" {
  type = string
  default = "1024"
}
variable "task_role_arn" {
  type = string
}
variable "exec_role_arn" {
  type = string
}
variable "container_image" {
  type = string
  default = "TO_REPLACE"
}
variable "container_port" {
  type = number
  default = 8080
}
variable "env_variables" {
  type = list(object({ name = string, value = string }))
  default = []
}
variable "secrets" {
  type = list(object({ name = string, valueFrom = string }))
  default = []
}
variable "log_group_name" {
  type = string
}
variable "log_retention_days" {
  type = number
  default = 5
}

# ECS Service
variable "cluster_arn" {
  type = string
}
variable "desired_count" {
  type = number
  default = 1
}
variable "assign_public_ip" {
  type = bool
  default = false
}

variable "tags" {
  type = map(string)
  default = {}
}