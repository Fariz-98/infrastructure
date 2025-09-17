output "endpoint" {
  value = module.rds.endpoint
}

output "port" {
  value = module.rds.port
}

output "rds_sg_id" {
  value = module.rds.rds_sg_id
}

output "rds_master_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "db_instance_id" {
  value = module.rds.db_instance_id
}