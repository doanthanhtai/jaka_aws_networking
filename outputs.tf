###############################################
# VPC
###############################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

###############################################
# ALB
###############################################

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.app_alb.dns_name
}

###############################################
# Auto Scaling Groups
###############################################

output "order_asg_name" {
  description = "The name of the order-service Auto Scaling Group"
  value       = aws_autoscaling_group.order_asg.name
}

output "payment_asg_name" {
  description = "The name of the payment-service Auto Scaling Group"
  value       = aws_autoscaling_group.payment_asg.name
}

output "order_db_endpoint" {
  description = "The connection endpoint of the order-service RDS instance"
  value       = aws_db_instance.order_db.endpoint
}

output "payment_db_endpoint" {
  description = "The connection endpoint of the payment-service RDS instance"
  value       = aws_db_instance.payment_db.endpoint
}
