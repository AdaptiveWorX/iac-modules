# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: MPL-2.0

output "tfc_role" {
  description = "The IAM role created for Terraform Cloud OIDC authentication"
  value = {
    arn      = aws_iam_role.tfc_role.arn
    name     = aws_iam_role.tfc_role.name
    policies = [for policy in aws_iam_role_policy.tfc_policy : policy.name]
  }
}

output "cross_account_role" {
  description = "The IAM role created for cross-account access from SecOps (if enabled)"
  value = var.enable_cross_account ? {
    arn      = aws_iam_role.tfc_secops_xa_role[0].arn
    name     = aws_iam_role.tfc_secops_xa_role[0].name
    policies = [for policy in aws_iam_role_policy.tfc_secops_xa_policy : policy.name]
  } : null
}
