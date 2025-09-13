# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# RAM Tagging Module - Outputs

output "total_resources_tagged" {
  description = "Total number of resources tagged"
  value       = local.total_resources_tagged
}

output "tagged_resource_summary" {
  description = "Summary of resources that were tagged"
  value = {
    vpc                = 1
    subnets            = length(data.aws_subnet.all)
    route_tables       = length(data.aws_route_table.all)
    internet_gateway   = 1
    dhcp_options       = 1
  }
}

output "tagging_complete" {
  description = "Indicates whether the tagging process is complete"
  value       = true
}

output "vpc_id" {
  description = "ID of the tagged VPC"
  value       = data.aws_vpc.shared.id
}
