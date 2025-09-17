variable "env" {
  type = string
  default = "env"
}

variable "alert_emails" {
  type = list(string)
  description = "Email recipients for pages"
}

variable "region" {
  type = string
  default = "ap-southeast-1"
}