variable "name_prefix" {
  description = "Prefix for resource name"
  type = string
}

variable "vpc_id" {
  description = "VPC ID where the DB will live"
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type = list(string)
}

variable "db_name" {
  description = "Initial database name"
  type = string
}

variable "engine" {
  description = "RDS engine"
  type = string
  default = "mysql"
}

variable "engine_version" {
  description = "RDS engine version"
  type = string
  default = "8.0" # MySQL
}

variable "instance_class" {
  description = "Instance size"
  type = string
  default = "db.t3.micro" # Smallest for dev
}

variable "allocated_storage" {
  description = "Initial storage (GiB)"
  type = number
  default = 20 # Smallest for dev
}

variable "max_allocated_storage" {
  description = "Storage autoscaling max (GiB). 0 to disable autoscaling"
  type = number
  default = 0
}

variable "storage_type" {
  description = "gp3 | gp2 | io2"
  type = string
  default = "gp3"
}

variable "publicly_accessible" {
  description = "Should the DB have public IP?"
  type = bool
  default = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups. 0 to disable backup"
  type = number
  default = 0
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type = bool
  default = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type = bool
  default = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups when instance is deleted"
  type = bool
  default = true
}

variable "deletion_protection" {
  description = "Protect instance from deletion"
  type = bool
  default = false
}

variable "multi_az" {
  description = "Provision a standby in another AZ"
  type = bool
  default = false
}

variable "performance_insights_enabled" {
  description = "Enable performance insights"
  type = bool
  default = false
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor version upgrades"
  type = bool
  default = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. 0 to disable"
  type = number
  default = 0
}

variable "master_username" {
  description = "Master username"
  type = string
  default = "admin"
}

variable "manage_master_user_password" {
  description = "Store master password in Secrets Manager"
  type = bool
  default = true
}

variable "tags" {
  description = "Extra tags to apply"
  type = map(string)
  default = {}
}