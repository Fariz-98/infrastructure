output "app_sg_id" {
  value = module.journal_service.app_sg_id
}

output "app_ecs_service_name" {
  value = module.journal_service.service_name
}

output "app_log_group_name" {
  value = module.journal_service.log_group_name
}

output "task_family" {
  value = module.journal_service.task_family
}

output "backend_app_container_name" {
  value = local.app_container_name
}