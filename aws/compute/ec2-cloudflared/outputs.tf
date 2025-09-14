# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.cloudflared.id
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.cloudflared.arn
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.cloudflared.name
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.cloudflared.id
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.cloudflared.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.cloudflared.arn
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the EC2 instances"
  value       = aws_iam_role.cloudflared.name
}

output "instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.cloudflared.arn
}

output "instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = aws_iam_instance_profile.cloudflared.name
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.cloudflared.id
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.cloudflared.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudflared.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudflared.arn
}

# Cross-account role outputs (moved from cross-account-roles.tf)
output "cross_account_role_arn" {
  description = "ARN of the cross-account role in the target account"
  value       = var.enable_cross_account_access && length(aws_iam_role.cross_account_access) > 0 ? aws_iam_role.cross_account_access[0].arn : null
}

output "cross_account_external_id_parameter" {
  description = "SSM parameter name containing the external ID for cross-account access"
  value       = var.enable_cross_account_access && length(aws_ssm_parameter.external_id) > 0 ? aws_ssm_parameter.external_id[0].name : null
}

output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "instance_type" {
  description = "The EC2 instance type being used"
  value       = var.instance_type
}

output "min_size" {
  description = "The minimum size of the Auto Scaling Group"
  value       = var.min_size
}

output "max_size" {
  description = "The maximum size of the Auto Scaling Group"
  value       = var.max_size
}

output "desired_capacity" {
  description = "The desired capacity of the Auto Scaling Group"
  value       = var.desired_capacity
}

output "vpc_id" {
  description = "The VPC ID where the instances are deployed"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "The subnet IDs where the instances are deployed"
  value       = var.private_subnet_ids
}

output "tags" {
  description = "The tags applied to the resources"
  value       = var.tags
}

output "tunnel_token_parameter" {
  description = "The SSM parameter name containing the tunnel token"
  value       = var.tunnel_token_parameter
}

output "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  value       = var.cloudflare_account_id
}

output "monitoring_enabled" {
  description = "Whether detailed monitoring is enabled"
  value       = var.enable_monitoring
}

output "auto_scaling_enabled" {
  description = "Whether auto-scaling is enabled"
  value       = var.enable_auto_scaling
}

output "auto_recovery_enabled" {
  description = "Whether auto-recovery is enabled"
  value       = var.enable_auto_recovery
}

output "ssm_session_manager_enabled" {
  description = "Whether SSM Session Manager is enabled for instance access"
  value       = var.enable_ssm_session_manager
}
