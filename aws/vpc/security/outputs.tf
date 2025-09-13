# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# NACL OUTPUTS
# ============================================================================

output "public_nacl_id" {
  description = "ID of the public network ACL"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "ID of the private network ACL"
  value       = aws_network_acl.private.id
}

output "data_nacl_id" {
  description = "ID of the data network ACL"
  value       = aws_network_acl.data.id
}

output "default_nacl_id" {
  description = "ID of the default network ACL (locked down)"
  value       = aws_default_network_acl.default.id
}

# ============================================================================
# SECURITY GROUP OUTPUTS
# ============================================================================

output "default_security_group_id" {
  description = "ID of the default security group (locked down)"
  value       = aws_default_security_group.default.id
}

output "base_security_group_id" {
  description = "ID of the base security group"
  value       = aws_security_group.base.id
}

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = try(aws_security_group.web[0].id, null)
}

output "app_security_group_id" {
  description = "ID of the application tier security group"
  value       = try(aws_security_group.app[0].id, null)
}

output "database_security_group_id" {
  description = "ID of the database tier security group"
  value       = try(aws_security_group.database[0].id, null)
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group"
  value       = try(aws_security_group.bastion[0].id, null)
}

# Structured security group output
output "security_group_ids" {
  description = "Map of security group IDs by tier"
  value = {
    base     = aws_security_group.base.id
    web      = try(aws_security_group.web[0].id, null)
    app      = try(aws_security_group.app[0].id, null)
    database = try(aws_security_group.database[0].id, null)
    bastion  = try(aws_security_group.bastion[0].id, null)
  }
}

# ============================================================================
# VPC PEERING OUTPUTS (DISABLED - Peering resources are commented out)
# ============================================================================

# output "peering_connection_ids" {
#   description = "Map of VPC peering connection IDs"
#   value       = { for k, v in aws_vpc_peering_connection.main : k => v.id }
# }

# output "peering_connection_accepter_ids" {
#   description = "Map of VPC peering connection accepter IDs"
#   value       = { for k, v in aws_vpc_peering_connection_accepter.peer : k => v.id }
# }

# output "peering_connection_status" {
#   description = "Map of VPC peering connection status"
#   value       = { for k, v in aws_vpc_peering_connection_accepter.peer : k => v.peer_vpc_peering_connection_id }
# }

# Placeholder outputs for peering (empty maps when peering is disabled)
output "peering_connection_ids" {
  description = "Map of VPC peering connection IDs (currently disabled)"
  value       = {}
}

output "peering_connection_accepter_ids" {
  description = "Map of VPC peering connection accepter IDs (currently disabled)"
  value       = {}
}

output "peering_connection_status" {
  description = "Map of VPC peering connection status (currently disabled)"
  value       = {}
}

# ============================================================================
# COMPUTED VALUES
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC (from data source)"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC (from data source)"
  value       = local.vpc_cidr
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
