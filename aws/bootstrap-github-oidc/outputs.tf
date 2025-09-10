output "role_arn" {
  value = aws_iam_role.deploy.arn
}

output "plan_arn" {
  value = aws_iam_role.plan.arn
}