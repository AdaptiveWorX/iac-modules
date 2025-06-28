# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "resource_share_id" {
  description = "ID of the RAM resource share"
  value       = aws_ram_resource_share.vpc.id
}

output "resource_share_arn" {
  description = "ARN of the RAM resource share"
  value       = aws_ram_resource_share.vpc.arn
}

output "resource_share_status" {
  description = "Status of the RAM resource share"
  value       = data.aws_ram_resource_share.status.status
}

output "shared_subnet_arns" {
  description = "List of subnet ARNs that are shared"
  value       = var.subnet_arns
}

output "shared_with_accounts" {
  description = "List of account IDs the resources are shared with"
  value       = var.share_with_accounts
}

output "shared_with_org_unit" {
  description = "Organization unit ARN the resources are shared with"
  value       = var.share_with_org_unit ? var.org_unit_arn : null
}

output "org_sharing_enabled" {
  description = "Whether RAM sharing with AWS Organizations is enabled"
  value       = var.enable_org_sharing
}
