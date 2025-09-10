variable "region" {
  description = "AWS region for the backend resources"
  type        = string
}

variable "env" {
  description = "Environment tag e.g. dev/stage/prod"
  type        = string
}

variable "github_owner" {
  type    = string
}

variable "github_repo" {
  type    = string
}

variable "branch" {
  type    = string
}