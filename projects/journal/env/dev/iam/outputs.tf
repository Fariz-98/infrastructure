output "ecs_task_role_arn" {
  value = module.ecs_task.role_arn
}

output "ecs_exec_role_arn" {
  value = module.ecs_exec.role_arn
}

output "github_app_role_arn" {
  value = module.github_app_deploy.role_arn
}