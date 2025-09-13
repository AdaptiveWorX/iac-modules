# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# ============================================================================
# VPC CORE OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "IPv6 CIDR block of the VPC"
  value       = try(aws_vpc.main.ipv6_cidr_block, null)
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "egress_only_internet_gateway_id" {
  description = "ID of the Egress-only Internet Gateway"
  value       = try(aws_egress_only_internet_gateway.main[0].id, null)
}

output "dhcp_options_id" {
  description = "ID of the DHCP Options Set"
  value       = aws_vpc_dhcp_options.main.id
}

output "default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}

# ============================================================================
# SUBNET OUTPUTS
# ============================================================================

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  description = "List of data subnet IDs"
  value       = aws_subnet.data[*].id
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}

output "data_subnet_arns" {
  description = "List of data subnet ARNs"
  value       = aws_subnet.data[*].arn
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "data_subnet_cidrs" {
  description = "List of data subnet CIDR blocks"
  value       = aws_subnet.data[*].cidr_block
}

# Structured subnet output for easier consumption
output "subnet_ids" {
  description = "Map of subnet IDs by tier"
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
    data    = aws_subnet.data[*].id
  }
}

output "subnet_cidrs" {
  description = "Map of subnet CIDR blocks by tier"
  value = {
    public  = aws_subnet.public[*].cidr_block
    private = aws_subnet.private[*].cidr_block
    data    = aws_subnet.data[*].cidr_block
  }
}

# ============================================================================
# NAT GATEWAY OUTPUTS
# ============================================================================

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.nat[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of NAT Gateway EIP allocation IDs"
  value       = aws_eip.nat[*].id
}

# ============================================================================
# ROUTE TABLE OUTPUTS
# ============================================================================

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "data_route_table_ids" {
  description = "List of data route table IDs"
  value       = aws_route_table.data[*].id
}

# Structured route table output
output "route_table_ids" {
  description = "Map of route table IDs by tier"
  value = {
    public  = [aws_route_table.public.id]
    private = aws_route_table.private[*].id
    data    = aws_route_table.data[*].id
  }
}

# ============================================================================
# VPC ENDPOINT OUTPUTS
# ============================================================================

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID of the DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].prefix_list_id, null)
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint IDs by service"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_names" {
  description = "Map of interface endpoint DNS names by service"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry[0].dns_name }
}

output "endpoints_security_group_id" {
  description = "ID of the security group for VPC interface endpoints"
  value       = try(aws_security_group.endpoints[0].id, null)
}

# ============================================================================
# RAM SHARING OUTPUTS
# ============================================================================

output "ram_share_arn" {
  description = "ARN of the RAM resource share"
  value       = try(aws_ram_resource_share.vpc[0].arn, null)
}

output "ram_share_id" {
  description = "ID of the RAM resource share"
  value       = try(aws_ram_resource_share.vpc[0].id, null)
}

output "shared_subnet_arns" {
  description = "List of subnet ARNs shared via RAM"
  value = length(local.all_accounts) > 0 || var.share_with_org_unit ? concat(
    aws_subnet.private[*].arn,
    aws_subnet.data[*].arn
  ) : []
}

# ============================================================================
# COMPUTED VALUES
# ============================================================================

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
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
