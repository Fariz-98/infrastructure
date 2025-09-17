variable "env" {
  type = string
}

variable "alert_emails" {
  type = list(string)
  description = "Email recipients for pages"
}

variable "region" {
  type = string
}