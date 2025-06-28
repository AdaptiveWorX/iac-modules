# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "IPv6 CIDR block of the VPC"
  value       = try(aws_vpc.main.ipv6_cidr_block, null)
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "eigw_id" {
  description = "ID of the Egress-only Internet Gateway"
  value       = try(aws_egress_only_internet_gateway.main[0].id, null)
}

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

output "all_subnet_ids" {
  description = "List of all subnet IDs"
  value       = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id,
    aws_subnet.data[*].id
  )
}

output "all_subnet_arns" {
  description = "List of all subnet ARNs for RAM sharing"
  value       = concat(
    aws_subnet.public[*].arn,
    aws_subnet.private[*].arn,
    aws_subnet.data[*].arn
  )
}

output "dhcp_options_id" {
  description = "ID of the DHCP options set"
  value       = aws_vpc_dhcp_options.main.id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}
