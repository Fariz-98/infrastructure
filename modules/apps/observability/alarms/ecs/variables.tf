variable "env" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

# Config
variable "period_seconds" {
  type = number
  default = 60
}
variable "cpu_threshold_pct" {
  type = number
  default = 85
}
variable "cpu_eval_periods" {
  type = number
  default = 15
}
variable "cpu_points_to_alarm" {
  type = number
  default = 12
}

variable "mem_threshold_pct" {
  type = number
  default = 85
}
variable "mem_eval_periods" {
  type = number
  default = 15
}
variable "mem_points_to_alarm" {
  type = number
  default = 12
}

variable "task_gap_eval_periods" {
  type = number
  default = 5
}
variable "task_gap_points_to_alarm" {
  type = number
  default = 4
}

variable "tags" {
  type = map(string)
  default = {}
}