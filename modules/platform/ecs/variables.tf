variable "name_prefix" {
  description = "Prefix for resource name"
  type = string
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights metrics"
  type = bool
  default = true
}

variable "enable_exec" {
  description = "Enable ECS Exec for debug shells via SSM"
  type = bool
  default = true
}

variable "exec_log_retention_days" {
  description = "Retention for ECS Exec Cloudwatch log group, enabled if enabled_exec is"
  type = number
  default = 30
}

variable "capacity_providers" {
  description = "Capacity providers to attach to clusters"
  type = list(string)
  default = ["FARGATE"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster. Each item: { capacity provider = string, weight = number, base = number }"
  type = list(object({
    capacity_provider = string
    weight = number
    base = number
  }))
  default = [
    { capacity_provider = "FARGATE", weight = 1, base = 0 }
  ]
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type = map(string)
  default = {}
}