# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "peering_connection_ids" {
  description = "Map of VPC peering connection IDs"
  value       = { for k, v in aws_vpc_peering_connection.main : k => v.id }
}

output "peering_connection_status" {
  description = "Map of VPC peering connection statuses"
  value       = { for k, v in aws_vpc_peering_connection_accepter.peer : k => v.accept_status }
}

output "peering_routes" {
  description = "List of all routes created for peering"
  value = {
    to_peer   = { for k, v in aws_route.to_peer : k => v.destination_cidr_block }
    from_peer = { for k, v in aws_route.from_peer : k => v.destination_cidr_block }
  }
}
