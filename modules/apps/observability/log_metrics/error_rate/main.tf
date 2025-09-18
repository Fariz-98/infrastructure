resource "aws_cloudwatch_log_metric_filter" "error_rate" {
  name = "tf-${var.env}-log-error-filter"
  log_group_name = var.log_group_name
  pattern = var.filter_pattern

  metric_transformation {
    name      = var.metric_name
    namespace = var.metric_namespace
    value     = "1"

    # For dashboards and scoping
    dimensions = var.metric_dimensions
  }
}

resource "aws_cloudwatch_metric_alarm" "error_rate_high" {
  alarm_name = "tf-${var.env}-${var.app_name}-errors"
  alarm_description = "${var.app_name} ERROR are is high"
  namespace = var.metric_namespace
  metric_name = var.metric_name
  statistic = "Sum"
  period = var.period_seconds
  evaluation_periods = var.evaluation_periods
  datapoints_to_alarm = var.datapoints_to_alarm
  threshold = var.error_threshold_per_min
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]
  dimensions = var.metric_dimensions
  insufficient_data_actions = []

  tags = merge(var.tags, { Name = "tf-${var.env}-${var.app_name}-errors", Kind = "log-error-rate" })
}