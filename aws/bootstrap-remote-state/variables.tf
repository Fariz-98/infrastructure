# Inputs that can be set at plan/apply or via tfvars
variable "region" {
  description = "AWS region for the backend resources"
  type = string
}

variable "environment" {
  description = "Environment tag e.g. dev/stage/prod"
  type = string
}

variable "state_bucket" {
  description = "Unique s3 bucket name"
  type = string
}

variable "state_prefix" {
  description = "Key prefix (folder) inside bucket to store separate env e.g. dev/"
  type = string
}

variable "lock_table" {
  description = "DynamoDB table name to state lock"
  type = string
}