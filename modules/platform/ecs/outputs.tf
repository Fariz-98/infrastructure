output "cluster_name" {
  value = aws_ecs_cluster.this.name
  description = "ECS cluster name"
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
  description = "ECS cluster ARN"
}

output "exec_log_group_name" {
  value = try(aws_cloudwatch_log_group.ecx_exec[0].name, null)
  description = "CloudWatch log group for ECS Exec (null if disabled)"
}