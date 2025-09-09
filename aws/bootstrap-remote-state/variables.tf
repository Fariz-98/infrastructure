# Inputs that can be set at plan/apply or via tfvars
variable "region" {
  description = "AWS region for the backend resources"
  type = string
  default = "ap-southeast-1"
}

variable "environment" {
  description = "Environment tag e.g. dev/stage/prod"
  type = string
  default = "dev"
}

variable "state_bucket" {
  description = "Unique s3 bucket name"
  type = string
  default = "dev-tf-state-bucket-matchbox3361"
}

variable "state_prefix" {
  description = "Key prefix (folder) inside bucket to store separate env e.g. dev/"
  type = string
  default = "dev/"
}

variable "lock_table" {
  description = "DynamoDB table name to state lock"
  type = string
  default = "dev-tf-state-lock"
}