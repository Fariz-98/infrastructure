# Availability (5xx code)
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "tf-${var.env}-alb-5xx"
  alarm_description = "ALB target 5xx elevated - user impact likely"
  namespace = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"
  statistic = "Sum"
  period = var.period_seconds
  evaluation_periods = var.five_xx_eval_periods
  threshold = var.five_xx_threshold
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    (var.dimension_key) = var.dimension_value
  }

  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-alb-5xx", Kind = "5xx" })
}

# Latency: p95 Target response time
resource "aws_cloudwatch_metric_alarm" "alb_p95_latency" {
  alarm_name          = "tf-${var.env}-alb-p95-latency"
  alarm_description = "ALB p95 TargetResponseTime high - many users are slow"
  namespace = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  extended_statistic = "p95"
  period = var.period_seconds
  evaluation_periods = var.p95_eval_periods
  threshold = var.p95_latency_threshold_s
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    (var.dimension_key) = var.dimension_value
  }

  treat_missing_data = "notBreaching"
  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.tags, { Name = "tf-${var.env}-alb-p95-latency", Kind = "p95-latency" })
}