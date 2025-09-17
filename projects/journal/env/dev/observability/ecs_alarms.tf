module "ecs_alarms" {
  source = "../../../../../modules/apps/observability/alarms/ecs"

  env = var.env
  sns_topic_arn = data.terraform_remote_state.alerts.outputs.alert_topic_arn
  cluster_name = data.terraform_remote_state.ecs_cluster.outputs.cluster_name
  service_name = data.terraform_remote_state.journal_service.outputs.app_ecs_service_name
}