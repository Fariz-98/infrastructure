output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_exec_role_arn" {
  value = aws_iam_role.ecs_exec.arn
}

output "github_app_role_arn" {
  value = aws_iam_role.github_app_deploy.arn
}