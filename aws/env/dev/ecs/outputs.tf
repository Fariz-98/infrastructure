output "cluster_arn" {
  value = aws_ecs_cluster.ecs-cluster.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.ecs-cluster.name
}