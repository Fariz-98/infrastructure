resource "aws_secretsmanager_secret" "this" {
  name = var.name
  description = var.description
  kms_key_id = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_secretsmanager_secret_version" "initial" {
  count = var.initial_kv == null ? 0 : 1
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.initial_kv)
}