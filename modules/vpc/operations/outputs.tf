# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# FLOW LOG OUTPUTS
# ============================================================================

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.vpc[0].id, null)
}

output "flow_log_s3_bucket" {
  description = "S3 bucket name for flow logs"
  value       = try(aws_s3_bucket.flow_logs[0].id, null)
}

output "flow_log_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs"
  value       = try(aws_s3_bucket.flow_logs[0].arn, null)
}

output "flow_log_cloudwatch_log_group" {
  description = "CloudWatch log group name for flow logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "flow_log_iam_role_arn" {
  description = "IAM role ARN for flow logs"
  value       = try(aws_iam_role.flow_logs[0].arn, null)
}

# ============================================================================
# MONITORING OUTPUTS
# ============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = try(aws_sns_topic.alarms[0].arn, null)
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alarms"
  value       = try(aws_sns_topic.alarms[0].name, null)
}

output "nat_gateway_bandwidth_alarm_arns" {
  description = "ARNs of NAT Gateway bandwidth alarms"
  value       = aws_cloudwatch_metric_alarm.nat_gateway_bandwidth[*].arn
}

output "nat_gateway_port_allocation_alarm_arns" {
  description = "ARNs of NAT Gateway port allocation error alarms"
  value       = aws_cloudwatch_metric_alarm.nat_gateway_error_port_allocation[*].arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = try("https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.vpc[0].dashboard_name}", null)
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = try(aws_cloudwatch_dashboard.vpc[0].dashboard_name, null)
}

# ============================================================================
# COMPUTED VALUES
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC (from data source)"
  value       = local.vpc_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.id
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ============================================================================
# MONITORING METRICS
# ============================================================================

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring_alarms
}

output "flow_logs_enabled" {
  description = "Whether flow logs are enabled"
  value       = var.enable_flow_logs
}

output "flow_log_destination_type" {
  description = "Type of flow log destination (s3 or cloudwatch)"
  value       = var.flow_log_destination
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways being monitored"
  value       = length(local.nat_gateway_ids)
}
