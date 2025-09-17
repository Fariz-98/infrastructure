variable "env" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "dimension_key" {
  description = "For shared ALB, go by target group: TargetGroup, for dedicated, go by lB: LoadBalancer"
  type = string
}

variable "dimension_value" {
  type = string
}

# Config
variable "five_xx_threshold" {
  type = number
  default = 5
}

variable "five_xx_eval_periods" {
  type = number
  default = 5
}

variable "period_seconds" {
  type = number
  default = 60
}

variable "p95_latency_threshold_s" {
  type = number
  default = 1.5
}

variable "p95_eval_periods" {
  type = number
  default = 10
}

variable "tags" {
  type = map(string)
  default = {}
}