# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "role_arn" {
  description = "ARN of the IAM role for Cloudflare tunnel cross-account access"
  value       = aws_iam_role.cloudflare_tunnel_access.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.cloudflare_tunnel_access.name
}

output "role_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.cloudflare_tunnel_access.unique_id
}

output "assume_role_policy" {
  description = "The assume role policy document"
  value       = aws_iam_role.cloudflare_tunnel_access.assume_role_policy
}

output "external_id" {
  description = "The external ID required for role assumption"
  value       = var.external_id
  sensitive   = true
}

output "max_session_duration" {
  description = "Maximum session duration in seconds"
  value       = aws_iam_role.cloudflare_tunnel_access.max_session_duration
}

output "enabled_services" {
  description = "Map of enabled service access permissions"
  value = {
    vpc         = var.enable_vpc_access
    rds         = var.enable_rds_access
    ecs         = var.enable_ecs_access
    ssm         = var.enable_ssm_access
    eks         = var.enable_eks_access
    lambda      = var.enable_lambda_access
    s3          = var.enable_s3_access
    cloudwatch  = var.enable_cloudwatch_access
  }
}

output "vpc_policy_arn" {
  description = "ARN of the VPC access policy (if enabled)"
  value       = var.enable_vpc_access ? aws_iam_role_policy.vpc_access[0].id : null
}

output "rds_policy_arn" {
  description = "ARN of the RDS access policy (if enabled)"
  value       = var.enable_rds_access ? aws_iam_role_policy.rds_access[0].id : null
}

output "ecs_policy_arn" {
  description = "ARN of the ECS access policy (if enabled)"
  value       = var.enable_ecs_access ? aws_iam_role_policy.ecs_access[0].id : null
}

output "ssm_policy_arn" {
  description = "ARN of the SSM access policy (if enabled)"
  value       = var.enable_ssm_access ? aws_iam_role_policy.ssm_access[0].id : null
}

output "eks_policy_arn" {
  description = "ARN of the EKS access policy (if enabled)"
  value       = var.enable_eks_access ? aws_iam_role_policy.eks_access[0].id : null
}

output "lambda_policy_arn" {
  description = "ARN of the Lambda access policy (if enabled)"
  value       = var.enable_lambda_access ? aws_iam_role_policy.lambda_access[0].id : null
}

output "s3_policy_arn" {
  description = "ARN of the S3 access policy (if enabled)"
  value       = var.enable_s3_access && length(var.allowed_s3_buckets) > 0 ? aws_iam_role_policy.s3_access[0].id : null
}

output "cloudwatch_policy_arn" {
  description = "ARN of the CloudWatch access policy (if enabled)"
  value       = var.enable_cloudwatch_access ? aws_iam_role_policy.cloudwatch_access[0].id : null
}

output "custom_policy_arn" {
  description = "ARN of the custom access policy (if provided)"
  value       = length(var.custom_policy_json) > 0 ? aws_iam_role_policy.custom_access[0].id : null
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter storing the role ARN (if created)"
  value       = var.create_ssm_parameter ? aws_ssm_parameter.role_arn[0].arn : null
}

output "ssm_parameter_name" {
  description = "Name of the SSM parameter storing the role ARN (if created)"
  value       = var.create_ssm_parameter ? aws_ssm_parameter.role_arn[0].name : null
}

output "allowed_regions" {
  description = "List of AWS regions where resources can be accessed"
  value       = var.allowed_regions
}

output "allowed_source_ips" {
  description = "List of source IP addresses allowed to assume the role"
  value       = var.allowed_source_ips
}

output "allowed_ecs_clusters" {
  description = "List of ECS cluster names that can be accessed"
  value       = var.allowed_ecs_clusters
}

output "allowed_s3_buckets" {
  description = "List of S3 bucket ARNs that can be accessed"
  value       = var.allowed_s3_buckets
}

output "managed_policy_arns" {
  description = "List of AWS managed policies attached to the role"
  value       = var.managed_policy_arns
}

output "role_tags" {
  description = "Tags applied to the IAM role"
  value       = aws_iam_role.cloudflare_tunnel_access.tags
}

output "trust_relationship" {
  description = "Trust relationship configuration for the role"
  value = {
    tunnel_role_arn    = var.tunnel_role_arn
    source_account     = var.source_account
    external_id        = var.external_id
    allowed_source_ips = var.allowed_source_ips
  }
  sensitive = true
}

output "role_creation_date" {
  description = "Date when the role was created"
  value       = aws_iam_role.cloudflare_tunnel_access.create_date
}

output "role_last_used" {
  description = "Information about the last time the role was used"
  value       = aws_iam_role.cloudflare_tunnel_access.role_last_used
}

output "assume_role_command" {
  description = "AWS CLI command to assume this role"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.cloudflare_tunnel_access.arn} --role-session-name cloudflare-tunnel --external-id <EXTERNAL_ID>"
}

output "cross_account_configuration" {
  description = "Complete cross-account configuration details"
  value = {
    role_arn             = aws_iam_role.cloudflare_tunnel_access.arn
    role_name            = aws_iam_role.cloudflare_tunnel_access.name
    source_account       = var.source_account
    target_account       = data.aws_caller_identity.current.account_id
    environment          = var.environment
    max_session_duration = var.max_session_duration
    enabled_services     = {
      vpc        = var.enable_vpc_access
      rds        = var.enable_rds_access
      ecs        = var.enable_ecs_access
      ssm        = var.enable_ssm_access
      eks        = var.enable_eks_access
      lambda     = var.enable_lambda_access
      s3         = var.enable_s3_access
      cloudwatch = var.enable_cloudwatch_access
    }
  }
}
