output "jdbc_url" {
  value = "jdbc:mysql://${aws_db_instance.rds.address}:${aws_db_instance.rds.port}/${aws_db_instance.rds.db_name}?serverTimezone=UTC"
}

output "rds_sg_id" {
  value = aws_security_group.db_sg.id
}