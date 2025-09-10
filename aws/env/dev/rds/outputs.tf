output "endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "port" {
  value = aws_db_instance.rds.port
}

output "rds_sg_id" {
  value = aws_security_group.db_sg.id
}

output "rds_master_secret_arn" {
  value = aws_db_instance.rds.master_user_secret[0].secret_arn
}

output "rds_db_name" {
  value = aws_db_instance.rds.db_name
}
