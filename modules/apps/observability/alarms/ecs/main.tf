locals {
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

# CPU Saturation
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name = "tf-${var.env}-ecs-${var.service_name}-cpu"
  alarm_description = "ECS service CPU > ${var.cpu_threshold_pct}% (sustained)"
  namespace = "ECS/ContainerInsights"
  metric_name = "CPUUtilization"
  statistic = "Average"
  period = var.period_seconds
  evaluation_periods = var.cpu_eval_periods
  datapoints_to_alarm = var.cpu_points_to_alarm
  threshold = var.cpu_threshold_pct
  comparison_operator = "GreaterThanThreshold"
  dimensions = local.dimensions
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-ecs-${var.service_name}-cpu", Kind = "cpu" })
}

# Memory Saturation
resource "aws_cloudwatch_metric_alarm" "ecs_mem_high" {
  alarm_name          = "tf-${var.env}-ecs-${var.service_name}-mem"
  alarm_description = "ECS Service Memory > ${var.mem_threshold_pct}% (sustained)"
  namespace = "ECS/ContainerInsights"
  metric_name = "MemoryUtilization"
  statistic = "Average"
  period = var.period_seconds
  evaluation_periods = var.mem_eval_periods
  datapoints_to_alarm = var.mem_points_to_alarm
  threshold = var.mem_threshold_pct
  comparison_operator = "GreaterThanThreshold"
  dimensions = local.dimensions
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-ecs-${var.service_name}-mem", Kind = "memory" })
}

# Task not running as configured
resource "aws_cloudwatch_metric_alarm" "ecs_task_gap" {
  alarm_name          = "tf-${var.env}-ecs-${var.service_name}-task-gap"
  alarm_description = "ECS service running fewer tasks than desired"
  comparison_operator = "GreaterThanThreshold"
  threshold = 0
  evaluation_periods = var.task_gap_eval_periods
  datapoints_to_alarm = var.task_gap_points_to_alarm
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  metric_query {
    id          = "desired"
    return_data = false
    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "DesiredTaskCount"
      period      = var.period_seconds
      stat        = "Average"
      dimensions  = local.dimensions
    }
  }

  metric_query {
    id = "running"
    return_data = false
    metric {
      namespace = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      period = var.period_seconds
      stat = "Average"
      dimensions = local.dimensions
    }
  }

  metric_query {
    id = "gap"
    expression = "desired - running"
    label = "TaskShortfall"
    return_data = true
  }

  tags = merge(var.tags, { Name = "tf-${var.env}-ecs-${var.service_name}-task-gap", Kind = "task-gap" })
}