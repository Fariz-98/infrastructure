output "app_sg_id" {
  value = aws_security_group.app_sg.id
}

output "app_ecs_service_name" {
  value = aws_ecs_service.journal.name
}

output "app_log_group_name" {
  value = aws_cloudwatch_log_group.journal.name
}