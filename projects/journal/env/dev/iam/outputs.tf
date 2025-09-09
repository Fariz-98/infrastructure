output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_exec.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}