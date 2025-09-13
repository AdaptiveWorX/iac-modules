# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "instance_id" {
  description = "ID of the EC2 instance running cloudflared"
  value       = aws_instance.cloudflared.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.cloudflared.arn
}

output "private_ip" {
  description = "Private IP address of the cloudflared instance"
  value       = aws_instance.cloudflared.private_ip
}

output "subnet_id" {
  description = "Subnet ID where the instance is deployed"
  value       = aws_instance.cloudflared.subnet_id
}

output "security_group_id" {
  description = "Security group ID for the cloudflared instance"
  value       = aws_security_group.cloudflared.id
}

output "iam_role_arn" {
  description = "IAM role ARN for the cloudflared instance"
  value       = aws_iam_role.cloudflared.arn
}

output "iam_role_name" {
  description = "IAM role name for the cloudflared instance"
  value       = aws_iam_role.cloudflared.name
}

output "instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = aws_iam_instance_profile.cloudflared.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for cloudflared logs"
  value       = aws_cloudwatch_log_group.cloudflared.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.cloudflared.arn
}

output "status_check_alarm_arn" {
  description = "ARN of the EC2 status check alarm"
  value       = aws_cloudwatch_metric_alarm.instance_status_check.arn
}

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}

output "auto_recovery_alarm_arn" {
  description = "ARN of the auto-recovery alarm"
  value       = aws_cloudwatch_metric_alarm.auto_recovery.arn
}

output "tunnel_status_parameter_name" {
  description = "SSM parameter name containing tunnel status (if created)"
  value       = var.create_status_parameter ? aws_ssm_parameter.tunnel_status[0].name : null
}

output "tunnel_status_parameter_arn" {
  description = "SSM parameter ARN containing tunnel status (if created)"
  value       = var.create_status_parameter ? aws_ssm_parameter.tunnel_status[0].arn : null
}

output "cross_account_role_arns" {
  description = "List of cross-account role ARNs that can be assumed"
  value = var.enable_cross_account_access ? [
    for account_id in var.target_account_ids : "arn:aws:iam::${account_id}:role/CloudflareTunnelAccess"
  ] : []
}

output "instance_tags" {
  description = "Tags applied to the EC2 instance"
  value       = aws_instance.cloudflared.tags
}

output "tunnel_configuration" {
  description = "Tunnel configuration details"
  value = {
    tunnel_name      = var.tunnel_name
    environment      = var.environment
    region           = var.region
    instance_type    = var.instance_type
    monitoring       = aws_instance.cloudflared.monitoring
    auto_recovery    = var.enable_auto_recovery
    log_retention    = var.log_retention_days
    metrics_interval = var.metrics_interval
  }
}

output "network_configuration" {
  description = "Network configuration for the cloudflared instance"
  value = {
    vpc_id            = var.vpc_id
    subnet_id         = aws_instance.cloudflared.subnet_id
    security_group_id = aws_security_group.cloudflared.id
    private_ip        = aws_instance.cloudflared.private_ip
    dns_servers       = var.dns_servers
  }
}

output "cloudflare_endpoints" {
  description = "Cloudflare API and tunnel endpoints"
  value = {
    api_endpoint    = var.cloudflare_api_endpoint
    tunnel_endpoint = var.cloudflare_tunnel_endpoint
  }
}

output "tunnel_routes" {
  description = "Configured tunnel routes"
  value       = var.tunnel_routes
  sensitive   = false
}

output "ssm_parameter_prefix" {
  description = "SSM parameter prefix for tunnel configuration"
  value       = var.ssm_parameter_prefix
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_instance.cloudflared.instance_state
}

output "launch_time" {
  description = "Time when the instance was launched"
  value       = aws_instance.cloudflared.launch_time
}

output "availability_zone" {
  description = "Availability zone where the instance is deployed"
  value       = aws_instance.cloudflared.availability_zone
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.cloudflared.ami
}

output "root_volume_id" {
  description = "ID of the root EBS volume"
  value       = aws_instance.cloudflared.root_block_device[0].volume_id
}

output "metadata_options" {
  description = "Instance metadata options configuration"
  value = {
    http_endpoint               = aws_instance.cloudflared.metadata_options[0].http_endpoint
    http_tokens                 = aws_instance.cloudflared.metadata_options[0].http_tokens
    http_put_response_hop_limit = aws_instance.cloudflared.metadata_options[0].http_put_response_hop_limit
    instance_metadata_tags      = aws_instance.cloudflared.metadata_options[0].instance_metadata_tags
  }
}
