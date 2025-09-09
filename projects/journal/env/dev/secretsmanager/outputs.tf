output "journal_secrets_arn" {
  description = "ARN for journal secretsmanager"
  value = aws_secretsmanager_secret.secrets.arn
}