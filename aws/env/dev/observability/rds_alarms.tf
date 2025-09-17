module "rds_alarms" {
  source = "../../../../modules/platform/observability/alarms/rds"
  env = var.env
  sns_topic_arn = module.alerts.topic_arn
  db_instance_id = data.terraform_remote_state.rds.outputs.db_instance_id
}