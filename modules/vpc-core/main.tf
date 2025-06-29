# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Base Module - Only VPC and Subnets
# This module has minimal blast radius and rarely needs changes

# Local variables for computed values
locals {
  # Compute domain name if not provided
  domain_name = var.domain_name != null ? var.domain_name : "${var.client_id}.${var.environment}"
  
  # Calculate subnet CIDRs with proper non-overlapping allocation
  # Strategy: Divide the /16 VPC into quarters for different subnet types
  # - First half (0-127): Reserved for larger private subnets (/19)
  # - Third quarter (128-191): Public and Data subnets (/21)
  # - Fourth quarter (192-255): Reserved for future use
  
  # For a /16 VPC:
  # - /17 blocks: 0-127 and 128-255
  # - /18 blocks: 0-63, 64-127, 128-191, 192-255
  
  subnet_cidrs = {
    # Private subnets: Use the first half of the VPC (0-127)
    # Each /19 is 32 IPs in the third octet, so they go: 0, 32, 64, 96, 128, 160
    private = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.private, i)
    ]
    
    # Public subnets: Start at the 128 mark (third quarter)
    # With a /16 VPC and /21 subnets (5 bits), we need to offset by 16 to start at 128
    public = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.public, i + 16)
    ]
    
    # Data subnets: Continue after public subnets
    # Public uses slots 16-21 (128.0 through 128.40), Data uses slots 22-27 (128.48 through 128.88)
    data = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, var.subnet_bits.data, i + 22)
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
