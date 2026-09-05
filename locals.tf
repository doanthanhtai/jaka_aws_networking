locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  ecr_registry  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  order_image   = "${local.ecr_registry}/${var.order_ecr_repo_name}:${var.image_tag}"
  payment_image = "${local.ecr_registry}/${var.payment_ecr_repo_name}:${var.image_tag}"

  order_db_url_param        = "/${var.environment}/order-db-url"
  order_db_password_param   = "/${var.environment}/order-db-password"
  payment_db_url_param      = "/${var.environment}/payment-db-url"
  payment_db_password_param = "/${var.environment}/payment-db-password"

  order_db_username   = "order_admin"
  payment_db_username = "payment_admin"

  order_app_db_username         = "order_user"
  payment_app_db_username       = "payment_user"
  order_app_db_password_param   = "/${var.environment}/order-user-db-password"
  payment_app_db_password_param = "/${var.environment}/payment-user-db-password"

  redis_primary_endpoint_param = "/${var.environment}/redis-primary-endpoint"
  redis_reader_endpoint_param  = "/${var.environment}/redis-reader-endpoint"
  redis_port_param             = "/${var.environment}/redis-port"
  redis_auth_token_param       = "/${var.environment}/redis-auth-token"

}
