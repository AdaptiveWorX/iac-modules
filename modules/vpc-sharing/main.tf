# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC RAM Module - Manages Resource Access Manager shares

# Merge account lists from both sources
locals {
  # Combine accounts from list and map formats
  all_accounts = merge(
    { for account in var.share_with_accounts : account => "Account ${account}" },
    var.share_with_accounts_map
  )
  
  # Create a formatted string of accounts with their names for documentation
  accounts_description = join(", ", [
    for account_id, account_name in local.all_accounts : "${account_name} (${account_id})"
  ])
}

# RAM Resource Share
resource "aws_ram_resource_share" "vpc" {
  name                      = "${var.environment}-vpc-share"
  allow_external_principals = false

  tags = merge(
    var.tags,
    {
      Name             = "${var.environment}-vpc-share"
      Environment      = var.environment
      ManagedBy        = "terraform"
      SharedAccounts   = local.accounts_description
    }
  )
}

# Associate subnets with the resource share
resource "aws_ram_resource_association" "subnets" {
  for_each = toset(var.subnet_arns)

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

# Share with specific accounts (supports both list and map formats)
resource "aws_ram_principal_association" "accounts" {
  for_each = local.all_accounts

  principal          = each.key
  resource_share_arn = aws_ram_resource_share.vpc.arn
}

# Share with organization unit
resource "aws_ram_principal_association" "org_unit" {
  count = var.share_with_org_unit && var.org_unit_arn != null ? 1 : 0

  principal          = var.org_unit_arn
  resource_share_arn = aws_ram_resource_share.vpc.arn
}
