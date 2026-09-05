###############################################
# Latest Ubuntu 22.04 AMI
###############################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

###############################################
# Launch Templates
###############################################

resource "aws_launch_template" "order_lt" {
  name_prefix   = "${local.name_prefix}-order-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.microservice_instance_profile.name
  }

  depends_on = [aws_ssm_parameter.order_app_user_db_password, aws_elasticache_replication_group.main]

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/templates/service-bootstrap.sh.tpl", {
    region                  = var.region
    ecr_registry            = local.ecr_registry
    image                   = local.order_image
    container_name          = "order-service"
    container_port          = aws_lb_target_group.order_tg.port
    db_host                 = aws_db_instance.order_db.address
    db_port                 = aws_db_instance.order_db.port
    db_name                 = aws_db_instance.order_db.db_name
    db_admin_username       = local.order_db_username
    db_admin_password_param = local.order_db_password_param
    db_app_username         = local.order_app_db_username
    db_url_param            = local.order_db_url_param
    db_app_password_param   = local.order_app_db_password_param
    cw_ssm_parameter_name   = aws_ssm_parameter.order_service_agent_config.name
    redis_endpoint_param    = local.redis_primary_endpoint_param
    redis_port_param        = local.redis_port_param
    redis_auth_param        = local.redis_auth_token_param
    redis_database_index    = 0
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${local.name_prefix}-order"
      SSMAccess = "true"
    }
  }
}

resource "aws_launch_template" "payment_lt" {
  name_prefix   = "${local.name_prefix}-payment-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.microservice_instance_profile.name
  }

  depends_on = [aws_ssm_parameter.payment_app_user_db_password, aws_elasticache_replication_group.main]

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(templatefile("${path.module}/templates/service-bootstrap.sh.tpl", {
    region                  = var.region
    ecr_registry            = local.ecr_registry
    image                   = local.payment_image
    container_name          = "payment-service"
    container_port          = aws_lb_target_group.payment_tg.port
    db_host                 = aws_db_instance.payment_db.address
    db_port                 = aws_db_instance.payment_db.port
    db_name                 = aws_db_instance.payment_db.db_name
    db_admin_username       = local.payment_db_username
    db_admin_password_param = local.payment_db_password_param
    db_app_username         = local.payment_app_db_username
    db_url_param            = local.payment_db_url_param
    db_app_password_param   = local.payment_app_db_password_param
    cw_ssm_parameter_name   = aws_ssm_parameter.payment_service_agent_config.name
    redis_endpoint_param    = local.redis_primary_endpoint_param
    redis_port_param        = local.redis_port_param
    redis_auth_param        = local.redis_auth_token_param
    redis_database_index    = 1
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${local.name_prefix}-payment"
      SSMAccess = "true"
    }
  }
}

###############################################
# Auto Scaling Groups
###############################################

resource "aws_autoscaling_group" "order_asg" {
  name = "${local.name_prefix}-order-asg"

  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.order_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.order_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-order-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "SSMAccess"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "payment_asg" {
  name = "${local.name_prefix}-payment-asg"

  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.payment_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.payment_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-payment-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "SSMAccess"
    value               = "true"
    propagate_at_launch = true
  }
}
