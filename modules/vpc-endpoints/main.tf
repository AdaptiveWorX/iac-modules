# Copyright (c) Adaptive Technology
# SPDX-License-Identifier: Apache-2.0

# VPC Endpoints Module - Manages VPC endpoints for AWS services

# S3 Gateway Endpoint (Free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

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

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

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
  vpc_id      = var.vpc_id

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

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.endpoint_subnet_ids
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
