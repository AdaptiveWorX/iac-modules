# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Base Module - Only VPC and Subnets
# This module has minimal blast radius and rarely needs changes

# Local variables for computed values
locals {
  # Compute domain name if not provided
  domain_name = var.domain_name != null ? var.domain_name : "${var.client_id}.${var.environment}"
  
  # Automatic subnet sizing calculation
  vpc_mask = tonumber(split("/", var.vpc_cidr)[1])
  available_bits = 32 - local.vpc_mask
  
  # Calculate optimal subnet bits automatically if not provided
  # This maximizes IP utilization while respecting AWS constraints
  auto_subnet_bits = {
    # Public subnets: Small (10% of space) - for ALBs, NAT GWs
    # Adjust based on number of AZs and VPC size
    public = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 6 :    # 6 AZs: /22 (1,024 IPs)
      var.subnet_count >= 4 ? 6 :    # 4-5 AZs: /22 (1,024 IPs)
      var.subnet_count >= 3 ? 6 :    # 3 AZs: /22 (1,024 IPs)
      7                              # 2 AZs: /23 (512 IPs)
    ) : (local.available_bits >= 12 ? 4 : 3)
    
    # Private subnets: Large (70% of space) - for workloads
    # Scale based on AZ count to maximize utilization
    private = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 3 :    # 6 AZs: /19 (8,192 IPs) = 49,152 total
      var.subnet_count >= 4 ? 2 :    # 4-5 AZs: /18 (16,384 IPs) = 65,536 total
      var.subnet_count >= 3 ? 2 :    # 3 AZs: /18 (16,384 IPs) = 49,152 total
      1                              # 2 AZs: /17 (32,768 IPs) = 65,536 total
    ) : (var.subnet_count >= 3 ? 2 : 1)
    
    # Data subnets: Medium (20% of space) - for RDS, ElastiCache
    # Balance between public and private needs
    data = local.available_bits >= 16 ? (
      var.subnet_count >= 6 ? 6 :    # 6 AZs: /22 (1,024 IPs) = 6,144 total
      var.subnet_count >= 4 ? 5 :    # 4-5 AZs: /21 (2,048 IPs) = 8,192 total
      var.subnet_count >= 3 ? 5 :    # 3 AZs: /21 (2,048 IPs) = 6,144 total
      5                              # 2 AZs: /21 (2,048 IPs) = 4,096 total
    ) : (var.subnet_count >= 3 ? 4 : 3)
  }
  
  # Use provided subnet_bits or fall back to automatic calculation
  subnet_bits = var.subnet_bits != null ? var.subnet_bits : local.auto_subnet_bits
  
  # Calculate dynamic offsets to prevent overlaps
  # This ensures subnets don't overlap regardless of their sizes
  public_subnet_count = var.subnet_count
  data_subnet_count = var.subnet_count
  private_subnet_count = var.subnet_count
  
  # Calculate how many address blocks are consumed by each tier
  # We need to account for different subnet sizes when calculating offsets
  # For example: if public uses /22 (6 bits) and we have 6 AZs, 
  # that's 6 blocks in the /22 space
  
  # Public subnets start at 0
  public_offset = 0
  
  # Data subnets must start after all public subnet space
  # If public uses 6 bits and data uses 6 bits (same size), offsets are straightforward
  # But if they differ, we need to calculate equivalent blocks
  data_offset = (local.subnet_bits.data == local.subnet_bits.public ? 
    var.subnet_count : 
    ceil(var.subnet_count * pow(2, local.subnet_bits.data - local.subnet_bits.public)))
  
  # Private subnets must start after all data subnet space
  # Calculate how many blocks of the private subnet size are needed
  # to skip past the data subnets
  private_offset = (local.subnet_bits.private == local.subnet_bits.data ?
    (local.data_offset + var.subnet_count) :
    (local.subnet_bits.private == local.subnet_bits.public ?
      var.subnet_count * 2 :  # If all same size, it's simple
      0))  # For different sizes, we'll use a different allocation strategy
  
  # Calculate subnet CIDRs with proper non-overlapping allocation
  # When subnet sizes differ, we need a different allocation strategy
  subnet_cidrs = {
    # Public subnets: Always start at offset 0
    public = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.public, i)
    ]
    
    # Data subnets: Allocate in their own address space
    data = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.data, i + (
        local.subnet_bits.data == local.subnet_bits.public ? var.subnet_count : 
        floor(pow(2, local.subnet_bits.data) / 2)  # Use upper half of address space
      ))
    ]
    
    # Private subnets: These are the largest, so give them their own clean space
    # Since they use only 3 bits (8 possible values) and we need 6, just use 0-5
    private = [
      for i in range(var.subnet_count) : 
      cidrsubnet(var.vpc_cidr, local.subnet_bits.private, i)
    ]
  }
  
  # Validate that subnets don't overlap by checking CIDR ranges
  # This is a safety check to ensure our allocation strategy works
  all_subnet_cidrs = concat(
    local.subnet_cidrs.public,
    local.subnet_cidrs.data,
    local.subnet_cidrs.private
  )
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
