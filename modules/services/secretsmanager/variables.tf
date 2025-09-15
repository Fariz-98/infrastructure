variable "name" {
  description = "Secret name (full path if path-styles names"
  type = string
}

variable "description" {
  description = "Secret description"
  type = string
  default = null
}

variable "kms_key_id" {
  description = "Optional CMK ARN/ID"
  type = string
  default = null
}

variable "recovery_window_in_days" {
  description = "Days to wait before final delete (0 for force delete immediately)"
  type = string
  default = 7
}

variable "initial_kv" {
  description = "Optional initial k/vmap written as secret_string"
  type = map(string)
  default = null
}

variable "tags" {
  description = "Extra tags"
  type = map(string)
  default = {}
}