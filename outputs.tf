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

output "redis_primary_endpoint" {
  description = "Primary endpoint of the shared Elasticache Redis replication group"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint of the shared Elasticache Redis replication group"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "Port of the shared Elasticache Redis replication group"
  value       = aws_elasticache_replication_group.main.port
}

output "s3_bucket_name" {
  description = "Name of the shared microservices S3 bucket (orders/, payments/ prefixes)"
  value       = aws_s3_bucket.microservices.id
}

output "s3_bucket_arn" {
  description = "ARN of the shared microservices S3 bucket"
  value       = aws_s3_bucket.microservices.arn
}

output "cloudwatch_dashboard_url" {
  description = "Console URL of the CloudWatch overview dashboard"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "alarms_sns_topic_arn" {
  description = "SNS topic that receives every CloudWatch alarm and RDS event"
  value       = aws_sns_topic.alarms.arn
}

output "app_log_group_names" {
  description = "CloudWatch log groups receiving the service container logs"
  value       = values(local.app_log_groups)
}