variable "region" {
  description = "AWS region for the backend resources"
  type        = string
  default = "ap-southeast-1"
}

variable "env" {
  description = "Environment tag e.g. dev/stage/prod"
  type        = string
  default = "dev"
}

variable "github_owner" {
  type    = string
  default = "Fariz-98"
}

variable "github_repo" {
  type    = string
  default = "infrastructure"
}

variable "branch" {
  type    = string
  default = "main"
}