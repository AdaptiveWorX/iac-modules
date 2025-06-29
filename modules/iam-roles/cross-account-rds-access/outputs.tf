// Copyright (c) Adaptive Technology, LLC.
// SPDX-License-Identifier: MPL-2.0

output "role_arn" {
  description = "ARN of the cross-account RDS access role"
  value       = aws_iam_role.rds_access_role.arn
}

output "role_name" {
  description = "Name of the cross-account RDS access role"
  value       = aws_iam_role.rds_access_role.name
}

output "rds_policy_arn" {
  description = "ARN of the RDS access policy"
  value       = aws_iam_policy.rds_access_policy.arn
}

output "s3_policy_arn" {
  description = "ARN of the S3 access policy, if created"
  value       = length(var.s3_bucket_arns) > 0 ? aws_iam_policy.s3_access_policy[0].arn : null
} 