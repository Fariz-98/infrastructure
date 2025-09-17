module "alb_alarms" {
  source = "../../../../../modules/apps/observability/alarms/alb"

  env = var.env
  sns_topic_arn = data.terraform_remote_state.alerts.outputs.alert_topic_arn
  dimension_key = "TargetGroup"
  dimension_value = data.terraform_remote_state.journal_service.outputs.target_group_arn_suffix
}