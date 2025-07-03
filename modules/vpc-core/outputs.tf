# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Core Module Outputs

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "The IPv6 CIDR block of the VPC"
  value       = try(aws_vpc.main.ipv6_cidr_block, null)
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "egress_only_internet_gateway_id" {
  description = "The ID of the Egress-only Internet Gateway"
  value       = try(aws_egress_only_internet_gateway.main[0].id, null)
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "data_subnet_ids" {
  description = "List of IDs of data subnets"
  value       = aws_subnet.data[*].id
}

output "data_subnet_arns" {
  description = "List of ARNs of data subnets"
  value       = aws_subnet.data[*].arn
}

output "data_subnet_cidrs" {
  description = "List of CIDR blocks of data subnets"
  value       = aws_subnet.data[*].cidr_block
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "subnet_count" {
  description = "Number of subnets per tier"
  value       = var.subnet_count
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "dhcp_options_id" {
  description = "The ID of the DHCP Options Set"
  value       = aws_vpc_dhcp_options.main.id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region_code" {
  description = "AWS region code"
  value       = var.region_code
}

# Expose subnet sizing information
output "subnet_bits_used" {
  description = "The subnet bits configuration used (either provided or automatically calculated)"
  value       = local.subnet_bits
}

output "automatic_subnet_sizing" {
  description = "Whether automatic subnet sizing was used"
  value       = var.subnet_bits == null
}

output "subnet_ip_counts" {
  description = "Number of IPs per subnet in each tier"
  value = {
    public  = pow(2, 32 - local.vpc_mask - local.subnet_bits.public) - 5   # AWS reserves 5 IPs
    private = pow(2, 32 - local.vpc_mask - local.subnet_bits.private) - 5
    data    = pow(2, 32 - local.vpc_mask - local.subnet_bits.data) - 5
  }
}

output "total_ip_utilization" {
  description = "Percentage of VPC IP space utilized"
  value = format("%.1f%%", (
    (var.subnet_count * pow(2, 32 - local.vpc_mask - local.subnet_bits.public)) +
    (var.subnet_count * pow(2, 32 - local.vpc_mask - local.subnet_bits.private)) +
    (var.subnet_count * pow(2, 32 - local.vpc_mask - local.subnet_bits.data))
  ) / pow(2, 32 - local.vpc_mask) * 100)
}
