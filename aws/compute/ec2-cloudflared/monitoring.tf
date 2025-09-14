# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# CloudWatch Log Group for Cloudflare tunnel logs
resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/aws/ec2/cloudflared/${var.environment}"
  retention_in_days = var.cloudwatch_log_retention

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-logs"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# CloudWatch Log Stream for instance logs
resource "aws_cloudwatch_log_stream" "cloudflared_instance" {
  name           = "${var.environment}-cloudflared-instance"
  log_group_name = aws_cloudwatch_log_group.cloudflared.name
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "cloudflared" {
  dashboard_name = "${var.environment}-cloudflare-tunnel"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "CPU Utilization" }],
            [".", ".", { stat = "Maximum", label = "CPU Max" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["CloudflareTunnel", "TunnelHealth", { stat = "Average", label = "Health" }],
            [".", "TunnelConnectivity", { stat = "Average", label = "Connectivity" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Tunnel Health"
          period  = 60
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Sum", label = "Network In" }],
            [".", "NetworkOut", { stat = "Sum", label = "Network Out" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Network Traffic"
          period  = 300
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.cloudflared.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarms

# High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors EC2 cpu utilization"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudflared.name
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-high-cpu-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Tunnel Health Alarm
resource "aws_cloudwatch_metric_alarm" "tunnel_health" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TunnelHealth"
  namespace           = "CloudflareTunnel"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when Cloudflare tunnel is unhealthy"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    Environment = var.environment
    Region      = var.aws_region
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-health-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MEM_USED"
  namespace           = "CloudflareTunnel"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when memory utilization is high"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    Environment = var.environment
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-high-memory-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# Instance Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-instance-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Alert when instance status check fails"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudflared.name
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-status-check-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# System Status Check Alarm
resource "aws_cloudwatch_metric_alarm" "system_status_check" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-system-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Alert when system status check fails"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudflared.name
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-system-check-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# ASG Instance Count Alarm
resource "aws_cloudwatch_metric_alarm" "asg_min_instances" {
  alarm_name          = "${var.environment}-cloudflare-tunnel-min-instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = "60"
  statistic           = "Average"
  threshold           = var.min_size
  alarm_description   = "Alert when ASG has fewer than minimum instances"
  alarm_actions       = var.notification_topic_arn != "" ? [var.notification_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.cloudflared.name
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-min-instances-alarm"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# CloudWatch Event Rule for Auto Scaling events
resource "aws_cloudwatch_event_rule" "autoscaling_events" {
  name        = "${var.environment}-cloudflare-tunnel-asg-events"
  description = "Capture Auto Scaling events for Cloudflare tunnel"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = [
      "EC2 Instance Launch Successful",
      "EC2 Instance Launch Unsuccessful",
      "EC2 Instance Terminate Successful",
      "EC2 Instance Terminate Unsuccessful"
    ]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.cloudflared.name]
    }
  })

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-asg-events"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# CloudWatch Event Target for sending to CloudWatch Logs
resource "aws_cloudwatch_event_target" "autoscaling_log" {
  rule      = aws_cloudwatch_event_rule.autoscaling_events.name
  target_id = "SendToCloudWatchLogs"
  arn       = aws_cloudwatch_log_group.cloudflared.arn
}

# SNS Topic for notifications (optional)
resource "aws_sns_topic" "cloudflared_alerts" {
  count = var.notification_topic_arn == "" ? 1 : 0

  name = "${var.environment}-cloudflare-tunnel-alerts"

  tags = merge(var.tags, {
    Name        = "${var.environment}-cloudflare-tunnel-alerts"
    Environment = var.environment
    Service     = "cloudflare-tunnel"
  })
}

# SNS Topic Subscription (optional)
resource "aws_sns_topic_subscription" "cloudflared_alerts_email" {
  count = var.notification_topic_arn == "" && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.cloudflared_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}
