variable "env" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "log_group_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "metric_namespace" {
  description = "Where to write the custom metric"
  type = string
}

variable "metric_name" {
  description = "Name for the metric, e.g. ErrorCount"
  type = string
}

variable "metric_dimensions" {
  description = "Dimensions to attach to the custom metric, e.g. {Env=dev, App=journal}"
  type = map(string)
  default = {}
}

variable "filter_pattern" {
  description = "What log to filter. For JSON: { $.level = \"ERROR\" }. Text: ERROR -HealthProbe -ELB-Check"
  type = string
}

# Config
variable "period_seconds" {
  type = number
  default = 60
}
variable "error_threshold_per_min" {
  type = number
  default = 5
}
variable "evaluation_periods" {
  type = number
  default = 5
}
variable "datapoints_to_alarm" {
  type = number
  default = 4
}

variable "tags" {
  type = map(string)
  default = {}
}