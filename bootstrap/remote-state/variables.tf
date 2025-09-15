# Inputs that can be set at plan/apply or via tfvars
variable "region" {
  description = "AWS region for the backend resources"
  type = string
}

variable "state_bucket" {
  description = "Unique s3 bucket name"
  type = string
  default = "dev-tf-state-bucket-matchbox3361"
}

variable "lock_table" {
  description = "DynamoDB table name to state lock"
  type = string
  default = "dev-tf-state-lock"
}