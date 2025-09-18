locals {
  app_name = "journal-backend"
}

module "app_error_rate_alarm" {
  source = "../../../../../modules/apps/observability/log_metrics/error_rate"

  env = var.env
  sns_topic_arn = data.terraform_remote_state.alerts.outputs.alert_topic_arn
  log_group_name = data.terraform_remote_state.journal_service.outputs.app_log_group_name
  app_name = local.app_name

  metric_namespace = "Custom/App"
  metric_name = "ErrorCount"

  filter_pattern = "{ $.level = \"ERROR\" }"
}