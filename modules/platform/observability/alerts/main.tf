# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = var.topic_name
  kms_master_key_id = var.kms_key_id

  tags = merge(var.tags, { Name = var.topic_name })
}

# SNS Policy
data "aws_caller_identity" "current" {}
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudWatchToPublish"
        Effect    = "Allow"
        Principal = { "Service" = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alerts.arn
        Condition = {
          "ArnLike" = {
            "AWS:SourceArn" = "arn:aws:cloudwatch:${var.region}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
        }
      }
    ]
  })
}
# Email subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alert_emails)
  endpoint  = each.value
  protocol  = "email"
  topic_arn = aws_sns_topic.alerts.arn
}