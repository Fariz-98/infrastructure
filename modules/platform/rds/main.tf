resource "aws_security_group" "rds_sg" {
  name = "${var.name_prefix}-rds-sg"
  description = "RDS SG"
  vpc_id = var.vpc_id

  egress {
    description = "Allow all egress"
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "${var.name_prefix}-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = merge(var.tags, { Name = "${var.name_prefix}-subnet-group" })
}

resource "aws_db_instance" "this" {
  identifier = var.name_prefix
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type = var.storage_type

  username = var.master_username
  manage_master_user_password  = var.manage_master_user_password

  db_name = var.db_name

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  delete_automated_backups = var.delete_automated_backups
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately = var.apply_immediately
  multi_az = var.multi_az
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval = var.monitoring_interval

  copy_tags_to_snapshot = true
  enabled_cloudwatch_logs_exports = var.enabled_log_exports

  tags = merge(var.tags, { Name = var.name_prefix })
}