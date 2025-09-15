output "db_instance_id" {
  value = aws_db_instance.this.id
  description = "DB Instance identifier"
}

output "address" {
  value = aws_db_instance.this.address
  description = "DNS address of the instance"
}

output "port" {
  value = aws_db_instance.this.port
  description = "Database port"
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
  description = "Endpoint (address:port)"
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
  description = "RDS security group ID"
}

output "master_user_secret_arn" {
  value = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
  description = "Secrets Manager ARN of the auto-managed master password if enabled"
}

output "db_name" {
  value = aws_db_instance.this.db_name
  description = "Initial DB Name"
}

output "subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
  description = "DB Subnet group name"
}