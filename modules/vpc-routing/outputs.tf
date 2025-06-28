# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

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

output "public_route_table_association_ids" {
  description = "List of public route table association IDs"
  value       = aws_route_table_association.public[*].id
}

output "private_route_table_association_ids" {
  description = "List of private route table association IDs"
  value       = aws_route_table_association.private[*].id
}

output "data_route_table_association_ids" {
  description = "List of data route table association IDs"
  value       = aws_route_table_association.data[*].id
}

output "all_route_table_ids" {
  description = "Map of all route table IDs by tier"
  value = {
    public  = aws_route_table.public.id
    private = aws_route_table.private[*].id
    data    = aws_route_table.data[*].id
  }
}
