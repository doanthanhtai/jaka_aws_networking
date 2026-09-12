resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ASG CPU Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "CPU alarm threshold"
              value = var.alarm_cpu_high_threshold
            }]
          }

          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order-service" }],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "CWAgent Memory Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "Memory alarm threshold"
              value = var.alarm_memory_high_threshold
            }]
          }

          metrics = [
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, { label = "order-service" }],
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "CWAgent Disk Utilization"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          annotations = {
            horizontal = [{
              label = "Disk alarm threshold"
              value = var.alarm_disk_high_threshold
            }]
          }

          metrics = [
            ["CWAgent", "disk_used_percent", "AutoScalingGroupName", aws_autoscaling_group.order_asg.name, "path", "/", { label = "order-service" }],
            ["CWAgent", "disk_used_percent", "AutoScalingGroupName", aws_autoscaling_group.payment_asg.name, "path", "/", { label = "payment-service" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB Errors and Latency"
          region = var.region
          period = 300
          view   = "timeSeries"

          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "Sum", label = "target 5xx" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.app_alb.arn_suffix, { stat = "p95", label = "target p95 latency" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU and Connections"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order CPU" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.order_db.identifier, { label = "order connections" }],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment CPU" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.payment_db.identifier, { label = "payment connections" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "Redis CPU and Memory"
          region = var.region
          period = 300
          stat   = "Average"
          view   = "timeSeries"

          metrics = concat(
            [
              for cluster_id in values(local.redis_cluster_ids) : [
                "AWS/ElastiCache",
                "CPUUtilization",
                "CacheClusterId",
                cluster_id,
                { label = "${cluster_id} CPU" }
              ]
            ],
            [
              for cluster_id in values(local.redis_cluster_ids) : [
                "AWS/ElastiCache",
                "DatabaseMemoryUsagePercentage",
                "CacheClusterId",
                cluster_id,
                { label = "${cluster_id} memory" }
              ]
            ]
          )
        }
      }
    ]
  })
}
