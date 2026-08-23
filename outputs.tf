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
# EC2
###############################################

output "ec2_order_private_ip_1" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_order_1.private_ip
}

output "ec2_order_private_ip_2" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_order_2.private_ip
}


output "ec2_payment_private_ip_1" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_payment_1.private_ip
}

output "ec2_payment_private_ip_2" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.ec2_payment_2.private_ip
}