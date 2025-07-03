# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Routing Module - Manages Route Tables and Routes

locals {
  # Determine the number of NAT gateways to create
  nat_gateway_count = var.enable_nat_gateway ? (
    var.nat_gateway_count != null ? var.nat_gateway_count : (
      var.single_nat_gateway ? 1 : length(var.availability_zones)
    )
  ) : 0
  
  # Ensure we don't exceed the number of available AZs
  actual_nat_gateway_count = min(local.nat_gateway_count, length(var.availability_zones))
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = local.actual_nat_gateway_count
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-eip-nat-az${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  count         = local.actual_nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-az${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  depends_on = [var.igw_id]
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
  # Route to the appropriate NAT gateway based on availability
  nat_gateway_id         = aws_nat_gateway.nat[min(count.index, local.actual_nat_gateway_count - 1)].id
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
  # Route to the appropriate NAT gateway based on availability
  nat_gateway_id         = aws_nat_gateway.nat[min(count.index, local.actual_nat_gateway_count - 1)].id
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
