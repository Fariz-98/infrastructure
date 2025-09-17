output "topic_arn" {
  description = "SNS topic ARN for alarms to publish to"
  value = aws_sns_topic.alerts.arn
}

output "topic_name" {
  value = aws_sns_topic.alerts.name
}