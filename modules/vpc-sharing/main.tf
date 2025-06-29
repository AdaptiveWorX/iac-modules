# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC RAM Module - Manages Resource Access Manager shares

# Enable RAM sharing with AWS Organizations
# Note: This requires permissions in the AWS Organizations management account
resource "aws_ram_sharing_with_organization" "main" {
  count    = var.enable_org_sharing ? 1 : 0
  provider = aws.org_management
  
  lifecycle {
    ignore_changes = all
  }
}

# RAM Resource Share
resource "aws_ram_resource_share" "vpc" {
  name                      = "${var.environment}-vpc-share"
  allow_external_principals = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpc-share"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Associate subnets with the resource share
resource "aws_ram_resource_association" "subnets" {
  for_each = toset(var.subnet_arns)

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

# Share with specific accounts
resource "aws_ram_principal_association" "accounts" {
  for_each = toset(var.share_with_accounts)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

# Share with organization unit
resource "aws_ram_principal_association" "org_unit" {
  count = var.share_with_org_unit && var.org_unit_arn != null ? 1 : 0

  principal          = var.org_unit_arn
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

# Data source to get shared resource status
data "aws_ram_resource_share" "status" {
  name            = aws_ram_resource_share.vpc.name
  resource_owner  = "SELF"

  depends_on = [
    aws_ram_resource_association.subnets,
    aws_ram_principal_association.accounts,
    aws_ram_principal_association.org_unit
  ]
}
