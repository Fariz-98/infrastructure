variable "name_prefix" {
  description = "Prefix applied to resource name"
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