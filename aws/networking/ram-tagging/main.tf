# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# RAM Tagging Module - Tags shared VPC resources in recipient accounts

# Data source to find the shared VPC
data "aws_vpc" "shared" {
  filter {
    name   = "owner-id"
    values = ["730335555486"] # worx-secops account ID
  }
  
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Data sources to find shared subnets
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  
  filter {
    name   = "owner-id"
    values = ["730335555486"]
  }
}

# Get details for each subnet
data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.all.ids)
  id       = each.value
}

# Data source to find route tables
data "aws_route_tables" "all" {
  vpc_id = data.aws_vpc.shared.id
  
  filter {
    name   = "owner-id"
    values = ["730335555486"]
  }
}

# Get details for each route table
data "aws_route_table" "all" {
  for_each       = toset(data.aws_route_tables.all.ids)
  route_table_id = each.value
}

# Data source to find internet gateway
data "aws_internet_gateway" "shared" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  
  filter {
    name   = "owner-id"
    values = ["730335555486"]
  }
}

# Data source to find DHCP options
data "aws_vpc_dhcp_options" "shared" {
  filter {
    name   = "dhcp-options-id"
    values = [data.aws_vpc.shared.dhcp_options_id]
  }
}

# Set tags on the VPC
resource "aws_ec2_tag" "vpc" {
  resource_id = data.aws_vpc.shared.id
  key         = "Name"
  value       = var.vpc_name
}

# Set tags on all subnets
resource "aws_ec2_tag" "subnets" {
  for_each = data.aws_subnet.all

  resource_id = each.value.id
  key         = "Name"
  value       = lookup(each.value.tags, "Name", "")
}

# Set tags on all route tables
resource "aws_ec2_tag" "route_tables" {
  for_each = data.aws_route_table.all

  resource_id = each.value.id
  key         = "Name"
  value       = lookup(each.value.tags, "Name", "")
}

# Set tags on the Internet Gateway
resource "aws_ec2_tag" "internet_gateway" {
  resource_id = data.aws_internet_gateway.shared.id
  key         = "Name"
  value       = "${var.environment}-igw"
}

# Set tags on the DHCP Options
resource "aws_ec2_tag" "dhcp_options" {
  resource_id = data.aws_vpc_dhcp_options.shared.id
  key         = "Name"
  value       = "${var.environment}-dhcp-options"
}

# Local variables for counting
locals {
  total_resources_tagged = (
    1 + # VPC
    length(data.aws_subnet.all) +
    length(data.aws_route_table.all) +
    1 + # IGW
    1   # DHCP Options
  )
}
