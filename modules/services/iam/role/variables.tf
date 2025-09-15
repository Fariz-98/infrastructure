variable "name" {
  description = "IAM role name"
  type = string
}

variable "trust_policy_json" {
  description = "Trust policy JSON"
  type = string
}

variable "path" {
  description = "Optional role path, e.g. /service/"
  type = string
  default = "/"
}

variable "max_session_duration" {
  description = "Session duration in seconds"
  type = number
  default = 3600
}

variable "permissions_boundary_arn" {
  description = "Optional permission boundary policy ARN"
  type = string
  default = null
}

variable "inline_policies" {
  description = "Map of {policy_name => policy_document_json}"
  type = map(string)
  default = {}
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type = list(string)
  default = []
}

variable "tags" {
  description = "Tags to apply"
  type = map(string)
  default = {}
}