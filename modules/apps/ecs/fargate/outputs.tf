output "app_sg_id" {
  value = aws_security_group.app.id
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "task_family" {
  value = aws_ecs_task_definition.app.family
}