locals {
  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name = "tf-${var.env}-rds-${var.db_instance_id}-cpu"
  alarm_description = "RDS CPU > ${var.cpu_threshold_pct}% (sustained)"
  namespace = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic = "Average"
  unit = "Percent"
  period = var.period_seconds
  evaluation_periods = var.cpu_eval_periods
  datapoints_to_alarm = var.cpu_points_to_alarm
  threshold = var.cpu_threshold_pct
  comparison_operator = "GreaterThanThreshold"
  dimensions = local.dimensions
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-rds-${var.db_instance_id}-cpu", Kind = "cpu" })
}

# Free Storage
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name = "tf-${var.env}-rds-${var.db_instance_id}-free-storage"
  alarm_description = "RDS free storage space is low"
  namespace = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  statistic = "Average"
  unit = "Bytes"
  period = var.period_seconds
  evaluation_periods = var.storage_eval_periods
  datapoints_to_alarm = var.storage_points_to_alarm
  threshold = var.free_storage_gb_threshold * 1024 * 1024 * 1024 # (Convert to Bytes)
  comparison_operator = "LessThanThreshold"
  dimensions = local.dimensions
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-rds-${var.db_instance_id}-free-storage", Kind = "free-storage" })
}