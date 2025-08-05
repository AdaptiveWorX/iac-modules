# VPC Routing Module

This module manages VPC routing infrastructure including NAT Gateways, Elastic IPs, route tables, and their associations. It supports both IPv4 and IPv6 routing configurations with flexible NAT Gateway deployment options.

## Features

- Creates and manages NAT Gateways with Elastic IPs
- Supports single NAT Gateway mode (cost optimization) or multi-AZ NAT Gateways (high availability)
- Creates separate route tables for public, private, and data subnets
- Supports IPv6 routing via Egress-Only Internet Gateway
- Per-AZ route tables for private and data subnets for better fault isolation
- Automatic route table associations with subnets
- Comprehensive tagging support

## Architecture

The module creates the following routing architecture:

- **Public Subnets**: Single shared route table with routes to Internet Gateway
- **Private Subnets**: Per-AZ route tables with routes to NAT Gateway(s)
- **Data Subnets**: Per-AZ route tables with routes to NAT Gateway(s)

## Usage

### High Availability Configuration (Recommended for Production)

```hcl
module "vpc_routing" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-routing?ref=v1.0.0"

  vpc_id             = module.vpc_core.vpc_id
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Gateway IDs from vpc-core module
  igw_id  = module.vpc_core.internet_gateway_id
  eigw_id = module.vpc_core.egress_only_internet_gateway_id
  
  # Subnet IDs from vpc-core module
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
  
  # Enable NAT Gateways (one per AZ)
  enable_nat_gateway  = true
  single_nat_gateway  = false
  
  # Enable IPv6 support
  enable_ipv6 = true
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

### Cost-Optimized Configuration (Single NAT Gateway)

```hcl
module "vpc_routing" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-routing?ref=v1.0.0"

  vpc_id             = module.vpc_core.vpc_id
  environment        = "dev"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Gateway IDs from vpc-core module
  igw_id  = module.vpc_core.internet_gateway_id
  eigw_id = module.vpc_core.egress_only_internet_gateway_id
  
  # Subnet IDs from vpc-core module
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
  
  # Use single NAT Gateway for cost savings
  enable_nat_gateway  = true
  single_nat_gateway  = true
  
  # Enable IPv6 support
  enable_ipv6 = true
  
  tags = {
    Environment = "dev"
    Project     = "infrastructure"
  }
}
```

### No NAT Gateway Configuration (Isolated Subnets)

```hcl
module "vpc_routing" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-routing?ref=v1.0.0"

  vpc_id             = module.vpc_core.vpc_id
  environment        = "isolated"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Gateway IDs from vpc-core module
  igw_id = module.vpc_core.internet_gateway_id
  
  # Subnet IDs from vpc-core module
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
  
  # Disable NAT Gateway for fully isolated private subnets
  enable_nat_gateway = false
  
  # Disable IPv6
  enable_ipv6 = false
  
  tags = {
    Environment = "isolated"
    Project     = "infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------:|
| vpc_id | VPC ID where route tables will be created | string | n/a | yes |
| environment | Environment name (e.g., sdlc, stage, prod) | string | n/a | yes |
| availability_zones | List of availability zones | list(string) | n/a | yes |
| igw_id | Internet Gateway ID | string | n/a | yes |
| eigw_id | Egress-only Internet Gateway ID (for IPv6) | string | null | no |
| public_subnet_ids | List of public subnet IDs | list(string) | n/a | yes |
| private_subnet_ids | List of private subnet IDs | list(string) | n/a | yes |
| data_subnet_ids | List of data subnet IDs | list(string) | n/a | yes |
| enable_nat_gateway | Whether to create NAT Gateway(s) | bool | true | no |
| single_nat_gateway | Use a single NAT Gateway for all AZs (cost savings) | bool | false | no |
| enable_ipv6 | Whether IPv6 is enabled | bool | true | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| public_route_table_id | ID of the public route table |
| private_route_table_ids | List of private route table IDs |
| data_route_table_ids | List of data route table IDs |
| public_route_table_association_ids | List of public route table association IDs |
| private_route_table_association_ids | List of private route table association IDs |
| data_route_table_association_ids | List of data route table association IDs |
| all_route_table_ids | Map of all route table IDs by tier |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_eip_ids | List of Elastic IP IDs for NAT Gateways |
| nat_eip_addresses | List of Elastic IP addresses for NAT Gateways |

## Cost Considerations

### NAT Gateway Pricing

- **Hourly charge**: ~$0.045 per hour per NAT Gateway
- **Data processing**: ~$0.045 per GB processed
- **Elastic IP**: No charge when attached to running NAT Gateway

### Cost Optimization Strategies

1. **Development/Test Environments**: Use `single_nat_gateway = true` to save costs
2. **Non-critical workloads**: Consider disabling NAT Gateway entirely if internet access isn't required
3. **Production**: Use multiple NAT Gateways for high availability
4. **Monitoring**: Set up CloudWatch alarms for NAT Gateway data processing costs

## High Availability Considerations

- **Multi-AZ NAT Gateways**: Each AZ gets its own NAT Gateway for fault isolation
- **Single NAT Gateway**: All traffic routes through one NAT Gateway (single point of failure)
- **Route Table Design**: Per-AZ route tables for private/data subnets enable independent failover

## IPv6 Support

When `enable_ipv6 = true` and an Egress-Only Internet Gateway ID is provided:
- Public subnets get bidirectional IPv6 internet connectivity via IGW
- Private/data subnets get outbound-only IPv6 connectivity via EIGW
- No NAT Gateway required for IPv6 traffic

## Requirements

- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0
- VPC Core module must be deployed first
