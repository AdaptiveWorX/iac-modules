# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Monitoring Module Outputs

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.vpc[0].id, null)
}

output "flow_log_s3_bucket_arn" {
  description = "ARN of the S3 bucket for VPC Flow Logs"
  value       = try(aws_s3_bucket.flow_logs[0].arn, null)
}

output "flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = try(aws_sns_topic.alarms[0].arn, null)
}

output "nat_gateway_bandwidth_alarm_names" {
  description = "Names of NAT Gateway bandwidth alarms"
  value       = try(aws_cloudwatch_metric_alarm.nat_gateway_bandwidth[*].alarm_name, [])
}

output "nat_gateway_port_allocation_alarm_names" {
  description = "Names of NAT Gateway port allocation error alarms"
  value       = try(aws_cloudwatch_metric_alarm.nat_gateway_error_port_allocation[*].alarm_name, [])
}
