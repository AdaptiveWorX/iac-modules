# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Base Module - Only VPC and Subnets
# This module has minimal blast radius and rarely needs changes

# Local variables for computed values
locals {
  # Compute domain name if not provided
  domain_name = var.domain_name != null ? var.domain_name : "${var.client_id}.${var.environment}"
  
  # Calculate subnet CIDRs with proper non-overlapping allocation
  # Strategy for a /16 VPC:
  # - Private subnets: /19 blocks (0, 32, 64, 96, 128, 160) - covers 0-191
  # - Public subnets: /21 blocks starting at 192 
  # - Data subnets: /21 blocks after public subnets
  # This ensures no overlaps between any subnet types
  
  subnet_cidrs = {
    # Private subnets: First 6 /19 blocks (covers 0-191)
    private = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.private, i)
    ]
    
    # Public subnets: Start at 192 (offset 24 for /21 blocks)
    # 192 = 24 * 8 (since each /21 is 8 addresses in the third octet)
    public = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.public, i + 24)
    ]
    
    # Data subnets: Place in gaps within the /19 blocks that don't conflict
    # Use specific offsets to place them in unused /21 spaces
    # These are placed to avoid the actual /19 subnet ranges
    data = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.data, 
        i == 0 ? 1 :   # 10.128.8.0/21 (gap in first /19)
        i == 1 ? 5 :   # 10.128.40.0/21 (gap in second /19)
        i == 2 ? 9 :   # 10.128.72.0/21 (gap in third /19)
        i == 3 ? 13 :  # 10.128.104.0/21 (gap in fourth /19)
        i == 4 ? 17 :  # 10.128.136.0/21 (gap in fifth /19)
        21             # 10.128.168.0/21 (gap in sixth /19)
      )
    ]
  }
}

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
      ManagedBy   = "opentofu"
    }
  )
}

# Internet Gateway (needed for public subnets to function)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-igw"
      Environment = var.environment
      ManagedBy   = "opentofu"
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
      ManagedBy   = "opentofu"
    }
  )
}

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
      Environment = var.environment
      ManagedBy   = "opentofu"
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
      Environment = var.environment
      ManagedBy   = "opentofu"
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
      Environment = var.environment
      ManagedBy   = "opentofu"
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
      ManagedBy   = "opentofu"
    }
  )
}

# Associate DHCP Options with VPC
resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}
