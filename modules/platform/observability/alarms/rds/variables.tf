variable "env" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "db_instance_id" {
  type = string
}

# Config
variable "period_seconds" {
  type = number
  default = 60
}
variable "cpu_threshold_pct" {
  type = number
  default = 80
}
variable "cpu_eval_periods" {
  type = number
  default = 10
}
variable "cpu_points_to_alarm" {
  type = number
  default = 8
}

variable "free_storage_gb_threshold" {
  type = number
  default = 5
}
variable "storage_eval_periods" {
  type = number
  default = 5
}
variable "storage_points_to_alarm" {
  type = number
  default = 4
}

variable "tags" {
  type = map(string)
  default = {}
}
