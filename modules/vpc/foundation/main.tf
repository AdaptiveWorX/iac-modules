# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Foundation Module - Core Infrastructure Layer
# Consolidates: vpc-core, vpc-routing, vpc-endpoints, vpc-sharing
# This layer contains resources that rarely change and form the foundation

terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Local variables for computed values
locals {
  # Compute domain name if not provided
  domain_name = var.domain_name != null ? var.domain_name : "${var.client_id}.${var.environment}"
  
  # Automatic subnet sizing calculation
  vpc_mask = tonumber(split("/", var.vpc_cidr)[1])
  available_bits = 32 - local.vpc_mask
  
  # Calculate optimal subnet bits automatically if not provided
  auto_subnet_bits = {
    public = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 7 :
      var.subnet_count >= 4 ? 7 :
      var.subnet_count >= 3 ? 6 :
      7
    ) : (local.available_bits >= 12 ? 4 : 3)
    
    private = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 3 :
      var.subnet_count >= 4 ? 3 :
      var.subnet_count >= 3 ? 2 :
      1
    ) : (var.subnet_count >= 3 ? 2 : 1)
    
    data = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 6 :
      var.subnet_count >= 4 ? 6 :
      var.subnet_count >= 3 ? 5 :
      5
    ) : (var.subnet_count >= 3 ? 4 : 3)
  }
  
  # Use provided subnet_bits or fall back to automatic calculation
  subnet_bits = var.subnet_bits != null ? var.subnet_bits : local.auto_subnet_bits
  
  # Calculate dynamic offsets to prevent overlaps
  public_subnet_count = var.subnet_count
  data_subnet_count = var.subnet_count
  private_subnet_count = var.subnet_count
  
  # Calculate number of subnets for each tier
  private_subnets = local.private_subnet_count
  data_subnets = local.data_subnet_count
  public_subnets = local.public_subnet_count
  
  # Calculate offsets in each subnet's own address space
  private_offset = 0
  data_offset = local.private_subnets * pow(2, local.subnet_bits.data - local.subnet_bits.private)
  public_offset = (local.private_subnets * pow(2, local.subnet_bits.public - local.subnet_bits.private)) + (local.data_subnets * pow(2, local.subnet_bits.public - local.subnet_bits.data))
  
  # Calculate subnet CIDRs with proper non-overlapping allocation
  subnet_cidrs = {
    private = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.private, local.private_offset + i)
    ]
    data = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.data, local.data_offset + i)
    ]
    public = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.public, local.public_offset + i)
    ]
  }
  
  # NAT Gateway configuration
  nat_gateway_count = var.enable_nat_gateway ? (
    var.nat_gateway_count != null ? var.nat_gateway_count : (
      var.single_nat_gateway ? 1 : length(var.availability_zones)
    )
  ) : 0
  
  # Ensure we don't exceed the number of available AZs
  actual_nat_gateway_count = min(local.nat_gateway_count, length(var.availability_zones))
  
  # RAM sharing configuration
  all_accounts = merge(
    { for account in var.share_with_accounts : account => "Account ${account}" },
    var.share_with_accounts_map
  )
  
  accounts_description = join(", ", [
    for account_id, account_name in local.all_accounts : "${account_name} (${account_id})"
  ])
}

# ============================================================================
# VPC CORE RESOURCES
# ============================================================================

# VPC Resource
resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  enable_dns_support               = true
  enable_dns_hostnames             = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-igw"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Egress-only Internet Gateway for IPv6
resource "aws_egress_only_internet_gateway" "main" {
  count  = var.enable_ipv6 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-eigw"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================================================
# SUBNETS
# ============================================================================

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs.public[count.index]
  ipv6_cidr_block         = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index) : null
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-subnet-public-${var.region_code}-az${count.index + 1}"
      Tier        = "public"
      Type        = "public"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = var.subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.private[count.index]
  ipv6_cidr_block   = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + var.subnet_count) : null
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-subnet-private-${var.region_code}-az${count.index + 1}"
      Tier        = "private"
      Type        = "private"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Data Subnets
resource "aws_subnet" "data" {
  count             = var.subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.data[count.index]
  ipv6_cidr_block   = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + (var.subnet_count * 2)) : null
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-subnet-data-${var.region_code}-az${count.index + 1}"
      Tier        = "data"
      Type        = "database"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "main" {
  domain_name_servers = ["AmazonProvidedDNS"]
  domain_name         = local.domain_name

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-dhcp-options"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Associate DHCP Options with VPC
resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

# ============================================================================
# NAT GATEWAYS AND ROUTING
# ============================================================================

# Elastic IPs for NAT Gateways
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

# NAT Gateways
resource "aws_nat_gateway" "nat" {
  count         = local.actual_nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-az${count.index + 1}"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

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
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "public_internet_gateway_ipv6" {
  count                       = var.enable_ipv6 ? 1 : 0
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main.id
}

# Private Route Tables (one per AZ for independent NAT Gateway failover)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

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
  count                  = var.enable_nat_gateway && local.actual_nat_gateway_count > 0 ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[min(count.index, max(local.actual_nat_gateway_count - 1, 0))].id
}

# Private Routes for IPv6 (via Egress-only Internet Gateway)
resource "aws_route" "private_eigw_ipv6" {
  count                       = var.enable_ipv6 ? length(var.availability_zones) : 0
  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.main[0].id
}

# Data Route Tables (one per AZ)
resource "aws_route_table" "data" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

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
  count                  = var.enable_nat_gateway && local.actual_nat_gateway_count > 0 ? length(var.availability_zones) : 0
  route_table_id         = aws_route_table.data[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[min(count.index, max(local.actual_nat_gateway_count - 1, 0))].id
}

# Data Routes for IPv6 (via Egress-only Internet Gateway)
resource "aws_route" "data_eigw_ipv6" {
  count                       = var.enable_ipv6 ? length(var.availability_zones) : 0
  route_table_id              = aws_route_table.data[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.main[0].id
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = length(aws_subnet.data)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data[count.index].id
}

# ============================================================================
# VPC ENDPOINTS
# ============================================================================

# S3 Gateway Endpoint (Free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    aws_route_table.data[*].id
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-s3-endpoint"
      Service     = "S3"
      Type        = "Gateway"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# DynamoDB Gateway Endpoint (Free)
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    aws_route_table.data[*].id
  )

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-dynamodb-endpoint"
      Service     = "DynamoDB"
      Type        = "Gateway"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Security Group for Interface Endpoints
resource "aws_security_group" "endpoints" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  name_prefix = "${var.environment}-vpc-endpoints-"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpc-endpoints-sg"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Interface Endpoints (Cost money - only create if specified)
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = length(var.interface_endpoints) > 0 ? [aws_security_group.endpoints[0].id] : []
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${each.value}-endpoint"
      Service     = each.value
      Type        = "Interface"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# ============================================================================
# RAM RESOURCE SHARING
# ============================================================================

# RAM Resource Share
resource "aws_ram_resource_share" "vpc" {
  count = length(local.all_accounts) > 0 || var.share_with_org_unit ? 1 : 0
  
  name                      = "${var.environment}-vpc-share"
  allow_external_principals = false

  tags = merge(
    var.tags,
    {
      Name             = "${var.environment}-vpc-share"
      Environment      = var.environment
      ManagedBy        = "terraform"
      # Removed SharedAccounts tag as it may contain invalid characters
    }
  )
}

# Associate subnets with the resource share
resource "aws_ram_resource_association" "subnets" {
  for_each = length(local.all_accounts) > 0 || var.share_with_org_unit ? merge(
    { for idx, subnet in aws_subnet.public : "public-${idx}" => subnet.arn },
    { for idx, subnet in aws_subnet.private : "private-${idx}" => subnet.arn },
    { for idx, subnet in aws_subnet.data : "data-${idx}" => subnet.arn }
  ) : {}

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.vpc[0].arn
}

# Share with specific accounts
resource "aws_ram_principal_association" "accounts" {
  for_each = length(local.all_accounts) > 0 ? local.all_accounts : {}

  principal          = each.key
  resource_share_arn = aws_ram_resource_share.vpc[0].arn
}

# Share with organization unit
resource "aws_ram_principal_association" "org_unit" {
  count = var.share_with_org_unit && var.org_unit_arn != null ? 1 : 0

  principal          = var.org_unit_arn
  resource_share_arn = aws_ram_resource_share.vpc[0].arn
}
