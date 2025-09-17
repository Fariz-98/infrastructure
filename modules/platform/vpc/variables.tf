variable "name_prefix" {
  description = "Prefix applied to resource name"
  type = string
}

variable "env" {
  type = string
}

# Just in case we want to tag per component in module
variable "tags" {
  description = "Common tags applied to all resources"
  type = map(string)
  default = {}
}

variable "region" {
  description = "AWS region"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type = string
}

variable "public_subnets" {
  description = "Map of public subnets"
  type = map(object({
    cidr = string
    az = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet CIDRs"
  type = map(object({
    cidr = string
    az = string
  }))
}

# Just in case we want NAT later, unused for now
variable "create_nat" {
  description = "Whether to create a single NAT for all private subnets"
  type = bool
  default = false
}

variable "interface_services" {
  description = "List of full interface endpoint service names"
  type = list(string)
  default = []
}

variable "create_s3_gateway_endpoint" {
  description = "Whether to create the S3 gateway endpoint on the private route table"
  type = bool
  default = true
}

# Logs
variable "enable_vpc_flow_logs" {
  description = "Turn VPC Flow Logs on/off"
  type = bool
  default = true
}

variable "vpc_flow_log_retention_days" {
  description = "CloudWatch Logs retention for VPC Flow Logs"
  type = number
  default = 7
}

variable "vpc_flow_log_traffic_type" {
  description = "ACCEPT | REJECT | ALL"
  type = string
  default = "ALL"
}

variable "vpc_flow_log_aggregation_seconds" {
  description = "60 or 600"
  type = number
  default = 60
}