variable "name_prefix" {
  description = "Prefix for resource name"
  type = string
}

variable "force_delete" {
  description = "Whether to allow repository deletion even if it contains images"
  type = bool
  default = false
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository"
  type = string
  default = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type = bool
  default = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type = string
  default = "AES256"
}

variable "kms_key" {
  description = "Optional KMS key for KMS encryption"
  type = string
  default = null
}

variable "lifecycle_policy" {
  description = "JSON lifecycle policy for the repository"
  type = string
  default = null
}

variable "tags" {
  description = "Extra tags to apply"
  type = map(string)
  default = {}
}