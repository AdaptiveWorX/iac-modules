# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Routing Module - Manages Route Tables and Routes

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.62.0"
    }
  }
  required_version = ">= 1.6.0"
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-rtb-public"
      Tier        = "public"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Public Routes
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count                       = var.enable_ipv6 ? 1 : 0
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = var.igw_id
}

# Private Route Tables (one per AZ for independent NAT Gateway failover)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-rtb-private-az${count.index + 1}"
      Tier        = "private"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Private Routes to NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[min(count.index, length(var.nat_gateway_ids) - 1)]
}

# Private Routes for IPv6 (via Egress-only Internet Gateway)
resource "aws_route" "private_eigw_ipv6" {
  count                       = var.enable_ipv6 && var.eigw_id != null ? length(var.availability_zones) : 0
  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = var.eigw_id
}

# Data Route Tables (one per AZ)
resource "aws_route_table" "data" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-rtb-data-az${count.index + 1}"
      Tier        = "data"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Data Routes to NAT Gateway
resource "aws_route" "data_nat_gateway" {
  count                  = var.enable_nat_gateway ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.data[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[min(count.index, length(var.nat_gateway_ids) - 1)]
}

# Data Routes for IPv6 (via Egress-only Internet Gateway)
resource "aws_route" "data_eigw_ipv6" {
  count                       = var.enable_ipv6 && var.eigw_id != null ? length(var.availability_zones) : 0
  route_table_id              = aws_route_table.data[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = var.eigw_id
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = length(var.data_subnet_ids)
  subnet_id      = var.data_subnet_ids[count.index]
  route_table_id = aws_route_table.data[count.index].id
}
