# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = var.topic_name
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, { Name = var.topic_name })
}

# Email subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alert_emails)
  endpoint  = each.value
  protocol  = "email"
  topic_arn = aws_sns_topic.alerts.arn
}