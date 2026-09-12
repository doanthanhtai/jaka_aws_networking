# Random password

resource "random_password" "order_db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "payment_db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "order_app_user" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "payment_app_user" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# DB subnet group

resource "aws_db_subnet_group" "db_subnet" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}


# RDS instances

resource "aws_db_instance" "order_db" {
  identifier        = "${local.name_prefix}-order-db"
  engine            = "postgres"
  engine_version    = var.postgres_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  db_name  = "orders"
  username = local.order_db_username
  password = random_password.order_db.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  multi_az                  = true
  backup_retention_period   = var.rds_retention_period
  skip_final_snapshot       = var.rds_skip_final_snapshot
  storage_encrypted         = true
  final_snapshot_identifier = "${local.name_prefix}-order-db-final-snapshot"

  parameter_group_name = aws_db_parameter_group.order_db.name

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  tags = {
    Name = "${local.name_prefix}-order-db"
  }
}

resource "aws_db_instance" "payment_db" {
  identifier        = "${local.name_prefix}-payment-db"
  engine            = "postgres"
  engine_version    = var.postgres_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  db_name  = "payments"
  username = local.payment_db_username
  password = random_password.payment_db.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  multi_az                  = true
  backup_retention_period   = var.rds_retention_period
  skip_final_snapshot       = var.rds_skip_final_snapshot
  storage_encrypted         = true
  final_snapshot_identifier = "${local.name_prefix}-payment-db-final-snapshot"

  parameter_group_name = aws_db_parameter_group.payment_db.name

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  tags = {
    Name = "${local.name_prefix}-payment-db"
  }
}

resource "aws_ssm_parameter" "order_db_url" {
  name  = local.order_db_url_param
  type  = "String"
  value = "jdbc:postgresql://${aws_db_instance.order_db.address}:${aws_db_instance.order_db.port}/${aws_db_instance.order_db.db_name}?sslmode=require"
}

resource "aws_ssm_parameter" "order_db_password" {
  name  = local.order_db_password_param
  type  = "SecureString"
  value = random_password.order_db.result
}

resource "aws_ssm_parameter" "payment_db_url" {
  name  = local.payment_db_url_param
  type  = "String"
  value = "jdbc:postgresql://${aws_db_instance.payment_db.address}:${aws_db_instance.payment_db.port}/${aws_db_instance.payment_db.db_name}?sslmode=require"
}

resource "aws_ssm_parameter" "payment_db_password" {
  name  = local.payment_db_password_param
  type  = "SecureString"
  value = random_password.payment_db.result
}

resource "aws_ssm_parameter" "order_app_user_db_password" {
  name  = local.order_app_db_password_param
  type  = "SecureString"
  value = random_password.order_app_user.result
}

resource "aws_ssm_parameter" "payment_app_user_db_password" {
  name  = local.payment_app_db_password_param
  type  = "SecureString"
  value = random_password.payment_app_user.result
}

resource "aws_db_parameter_group" "order_db" {
  name   = "${local.name_prefix}-order-pg"
  family = "postgres16"
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_parameter_group" "payment_db" {
  name   = "${local.name_prefix}-payment-pg"
  family = "postgres16"
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

}
