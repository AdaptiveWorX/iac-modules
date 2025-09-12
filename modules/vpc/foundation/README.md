# VPC Foundation Module

## Overview

The VPC Foundation module provides the core networking infrastructure layer that forms the foundation of AdaptiveWorX AWS VPC architecture. This module is part of a 3-layer VPC architecture designed for security isolation and scalability.

This module manages resources that rarely change once deployed:
- VPC and DHCP Options
- Subnets (public, private, data)
- Internet and NAT Gateways
- Route Tables and Routes
- VPC Endpoints (Gateway and Interface)
- RAM Resource Sharing
- Layer-specific tagging for connectivity

## Architecture

The module creates a three-tier subnet architecture:
- **Public Subnets**: Internet-facing resources with public IPs
- **Private Subnets**: Application tier with NAT Gateway access
- **Data Subnets**: Database tier with restricted access

### 3-Layer VPC Architecture Integration

The Foundation layer works in conjunction with:
- **Security Layer**: Hosts security tools, monitoring, and compliance resources
- **Operations Layer**: Contains CI/CD pipelines, logging, and operational tools

Connectivity between layers is managed by the vpc-connectivity module:
- Foundation → Security (allowed)
- Foundation → Operations (allowed)
- Security → Operations (allowed)

## Usage

```hcl
module "vpc_foundation" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-foundation?ref=v1.0.0"

  environment        = "dev"
  vpc_cidr          = "10.192.0.0/16"
  region_code       = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  subnet_count      = 6  # Should match the number of AZs in the region

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA

  # VPC Endpoints
  enable_dynamodb_endpoint = true
  interface_endpoints = ["ec2", "ecs", "ssm", "logs"]

  # RAM Sharing
  share_with_accounts_map = {
    "123456789012" = "Development Account"
    "234567890123" = "Staging Account"
  }

  tags = {
    Environment = "dev"
    Layer       = "foundation"  # Important for connectivity discovery
    Region      = "us-east-1"   # Used by vpc-connectivity module
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}
```

## Features

### Automatic Subnet Sizing
The module automatically calculates optimal subnet sizes based on your VPC CIDR and number of availability zones. The module deploys subnets across all specified availability zones by default - you should set `subnet_count` to match the number of AZs in your region (e.g., 6 for us-east-1, 4 for us-west-2). You can override the automatic sizing with the `subnet_bits` variable if needed.

### Flexible NAT Gateway Configuration
- Single NAT Gateway for all AZs (cost optimization)
- One NAT Gateway per AZ (high availability)
- Custom number of NAT Gateways

### VPC Endpoints
- S3 Gateway Endpoint (always created, free)
- DynamoDB Gateway Endpoint (optional, free)
- Interface Endpoints for AWS services (optional, costs apply)

### RAM Resource Sharing
Share private and data subnets with other AWS accounts or Organization Units for centralized VPC management.

### Layer Tagging
The module automatically tags the VPC with layer information, enabling:
- Automatic discovery by the vpc-connectivity module
- Layer-based connectivity policies
- Environment and region-based filtering

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | CIDR block for the VPC | string | - | yes |
| environment | Environment name (dev, staging, prod) | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| region_code | AWS region code | string | - | yes |
| subnet_count | Number of subnets per tier (should match number of AZs) | number | 2 | no |
| enable_nat_gateway | Enable NAT Gateway | bool | false | no |
| single_nat_gateway | Use single NAT Gateway | bool | false | no |
| interface_endpoints | List of interface endpoints | list(string) | [] | no |
| share_with_accounts_map | Map of account IDs to share with | map(string) | {} | no |
| tags | Additional tags for resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| subnet_ids | Map of subnet IDs by tier |
| nat_gateway_ids | List of NAT Gateway IDs |
| route_table_ids | Map of route table IDs by tier |
| ram_share_arn | ARN of RAM resource share |
| layer | Layer identifier (always "foundation") |

## Multi-Region Deployment

When deploying across multiple regions:
1. Each region gets its own Foundation VPC
2. VPCs are tagged with Environment, Layer, and Region
3. The vpc-connectivity module discovers and connects VPCs based on these tags
4. Connectivity strategy varies by environment:
   - DEV/Stage: VPC Peering (simpler, cost-effective)
   - Production: Transit Gateway (scalable, hub-and-spoke)

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0
- Proper tagging for connectivity discovery

## Related Modules

- **vpc-security**: Security layer VPC module
- **vpc-operations**: Operations layer VPC module
- **vpc-connectivity**: Manages connectivity between VPC layers
