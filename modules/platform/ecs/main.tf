resource "aws_cloudwatch_log_group" "ecx_exec" {
  count = var.enable_exec ? 1 : 0
  name = "/ecs/${var.name_prefix}-exec"
  retention_in_days = var.exec_log_retention_days
  tags = merge(var.tags, { Name = "${var.name_prefix}-exec-log" })
}

resource "aws_ecs_cluster" "this" {
  name = var.name_prefix

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      name = "containerInsights"
      value = "enabled"
    }
  }

  dynamic "configuration" {
    for_each = var.enable_exec ? [1] : []
    content {
      execute_command_configuration {
        logging = "OVERRIDE"
        log_configuration {
          cloud_watch_log_group_name = aws_cloudwatch_log_group.ecx_exec[0].name
        }
      }
    }
  }

  tags = merge(var.tags, { Name = var.name_prefix })
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = length(var.capacity_providers) > 0 ? 1 : 0
  cluster_name = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight = default_capacity_provider_strategy.value.weight
      base = default_capacity_provider_strategy.value.base
    }
  }
}