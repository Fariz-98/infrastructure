output "journal_secrets_arn" {
  description = "ARN for journal secretsmanager"
  value = module.journal_secret.secret_arn
}