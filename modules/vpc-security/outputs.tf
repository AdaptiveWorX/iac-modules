# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

output "public_nacl_id" {
  description = "ID of the public NACL"
  value       = aws_network_acl.public.id
}

output "public_nacl_name" {
  description = "Name of the public NACL"
  value       = aws_network_acl.public.tags["Name"]
}

output "private_nacl_id" {
  description = "ID of the private NACL"
  value       = aws_network_acl.private.id
}

output "private_nacl_name" {
  description = "Name of the private NACL"
  value       = aws_network_acl.private.tags["Name"]
}

output "data_nacl_id" {
  description = "ID of the data NACL"
  value       = aws_network_acl.data.id
}

output "data_nacl_name" {
  description = "Name of the data NACL"
  value       = aws_network_acl.data.tags["Name"]
}

output "default_nacl_id" {
  description = "ID of the default NACL (configured to deny all)"
  value       = aws_default_network_acl.default.id
}

output "nacl_ids" {
  description = "Map of all NACL IDs by tier"
  value = {
    public  = aws_network_acl.public.id
    private = aws_network_acl.private.id
    data    = aws_network_acl.data.id
    default = aws_default_network_acl.default.id
  }
}

output "nacl_names" {
  description = "Map of all NACL names by tier"
  value = {
    public  = aws_network_acl.public.tags["Name"]
    private = aws_network_acl.private.tags["Name"]
    data    = aws_network_acl.data.tags["Name"]
  }
}

output "public_nacl_association_ids" {
  description = "List of public NACL association IDs"
  value       = aws_network_acl_association.public[*].id
}

output "private_nacl_association_ids" {
  description = "List of private NACL association IDs"
  value       = aws_network_acl_association.private[*].id
}

output "data_nacl_association_ids" {
  description = "List of data NACL association IDs"
  value       = aws_network_acl_association.data[*].id
}

output "default_security_group_id" {
  description = "ID of the default security group (configured to deny all)"
  value       = aws_default_security_group.default.id
}
