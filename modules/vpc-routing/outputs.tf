# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Routing Module Outputs

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = try(aws_nat_gateway.nat[*].id, [])
}

output "nat_gateway_eip_ids" {
  description = "List of Elastic IP IDs for NAT Gateways"
  value       = try(aws_eip.nat[*].id, [])
}

output "nat_gateway_eip_addresses" {
  description = "List of Elastic IP addresses for NAT Gateways"
  value       = try(aws_eip.nat[*].public_ip, [])
}

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

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = local.actual_nat_gateway_count
}
