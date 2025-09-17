variable "alert_emails" {
  description = "list of email addresses to receive pages"
  type = list(string)
  default = []
}

variable "topic_name" {
  description = "Explicit SNS topic name"
  type = string
  default = ""
}

variable "kms_key_id" {
  description = "KSM key for SNS SSE"
  type = string
  default = "alias/aws/sns" # AWS managed default
}

variable "tags" {
  type = map(string)
  default = {}
}