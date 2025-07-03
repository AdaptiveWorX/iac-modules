# VPC Core Module

This module creates the foundational VPC infrastructure including the VPC itself, subnets across three tiers (public, private, data), internet gateways, and DHCP options.

## Features

- **Automatic Subnet Sizing**: Intelligently calculates optimal subnet sizes to maximize IP utilization
- **Multi-AZ Support**: Creates subnets across all specified availability zones
- **IPv6 Support**: Optional dual-stack configuration
- **Three-Tier Architecture**: Public, Private, and Data subnet tiers
- **Non-Overlapping Subnets**: Dynamic offset calculation prevents CIDR conflicts

## Automatic Subnet Sizing

The module now features automatic subnet sizing that maximizes IP utilization without manual configuration. When `subnet_bits` is not provided (default), the module automatically calculates optimal sizes based on:

- VPC CIDR size
- Number of availability zones
- AWS constraints and best practices
- Tier requirements (70% private, 20% data, 10% public)

### Example Automatic Allocations

**For a /16 VPC:**

6 AZs (e.g., us-east-1):
- **Public**: 6 × /22 = 6,144 IPs (9.4%)
- **Private**: 6 × /19 = 49,152 IPs (75.0%)
- **Data**: 6 × /22 = 6,144 IPs (9.4%)
- **Total Utilization**: ~93.8%

4 AZs (e.g., us-west-2):
- **Public**: 4 × /22 = 4,096 IPs (6.3%)
- **Private**: 4 × /18 = 65,536 IPs (100% of VPC!)
- **Data**: 4 × /21 = 8,192 IPs (12.5%)
- **Total Utilization**: ~81.2%*

3 AZs (most regions):
- **Public**: 3 × /22 = 3,072 IPs (4.7%)
- **Private**: 3 × /18 = 49,152 IPs (75.0%)
- **Data**: 3 × /21 = 6,144 IPs (9.4%)
- **Total Utilization**: ~89.1%

2 AZs (e.g., us-west-1):
- **Public**: 2 × /23 = 1,024 IPs (1.6%)
- **Private**: 2 × /17 = 65,536 IPs (100% of VPC!)
- **Data**: 2 × /21 = 4,096 IPs (6.3%)
- **Total Utilization**: ~87.5%*

*Note: Private subnets may exceed VPC size in calculation but are limited by available space.

## Usage

### Basic Usage (Automatic Sizing)

```hcl
module "vpc_core" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-core?ref=v1.0.2"
  
  vpc_cidr           = "10.0.0.0/16"
  environment        = "production"
  region_code        = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  tags = {
    Environment = "production"
    Project     = "infrastructure"
  }
}
```

### Manual Subnet Sizing Override

```hcl
module "vpc_core" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-core?ref=v1.0.2"
  
  vpc_cidr           = "10.0.0.0/16"
  environment        = "production"
  region_code        = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Optional: Override automatic sizing
  subnet_bits = {
    public  = 6  # /22 subnets (1,024 IPs)
    private = 2  # /18 subnets (16,384 IPs)
    data    = 5  # /21 subnets (2,048 IPs)
  }
  
  tags = {
    Environment = "production"
    Project     = "infrastructure"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform/opentofu | >= 1.6.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| environment | Environment name (e.g., sdlc, stage, prod) | `string` | n/a | yes |
| region_code | AWS region code (e.g., use1, usw2) | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| client_id | Client identifier | `string` | `"adaptive"` | no |
| subnet_count | Number of subnets to create per tier | `number` | `2` | no |
| subnet_bits | Number of additional bits for subnet CIDR calculation. If not provided, optimal sizes will be calculated automatically | `object({public=number, private=number, data=number})` | `null` | no |
| enable_ipv6 | Enable IPv6 for the VPC | `bool` | `true` | no |
| domain_name | Domain name for DHCP options | `string` | `null` | no |
| tags | Additional tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| vpc_ipv6_cidr | The IPv6 CIDR block of the VPC |
| internet_gateway_id | The ID of the Internet Gateway |
| egress_only_internet_gateway_id | The ID of the Egress-only Internet Gateway |
| public_subnet_ids | List of IDs of public subnets |
| public_subnet_arns | List of ARNs of public subnets |
| public_subnet_cidrs | List of CIDR blocks of public subnets |
| private_subnet_ids | List of IDs of private subnets |
| private_subnet_arns | List of ARNs of private subnets |
| private_subnet_cidrs | List of CIDR blocks of private subnets |
| data_subnet_ids | List of IDs of data subnets |
| data_subnet_arns | List of ARNs of data subnets |
| data_subnet_cidrs | List of CIDR blocks of data subnets |
| availability_zones | List of availability zones used |
| subnet_count | Number of subnets per tier |
| default_network_acl_id | The ID of the default network ACL |
| dhcp_options_id | The ID of the DHCP Options Set |
| environment | Environment name |
| region_code | AWS region code |
| subnet_bits_used | The subnet bits configuration used (either provided or automatically calculated) |
| automatic_subnet_sizing | Whether automatic subnet sizing was used |
| subnet_ip_counts | Number of usable IPs per subnet in each tier (AWS reserves 5 IPs) |
| total_ip_utilization | Percentage of VPC IP space utilized |

## Resources Created

- 1 × VPC
- 1 × Internet Gateway
- 1 × DHCP Options Set (optional)
- 1 × Egress-only Internet Gateway (if IPv6 enabled)
- N × Public Subnets (based on AZ count)
- N × Private Subnets (based on AZ count)
- N × Data Subnets (based on AZ count)

## Subnet Tier Architecture

### Public Subnets
- Purpose: Load balancers, NAT gateways, bastion hosts
- Auto-assign public IPs: Yes
- Typical usage: 10% of VPC space

### Private Subnets
- Purpose: Application workloads, containers, compute instances
- Auto-assign public IPs: No
- Typical usage: 70% of VPC space

### Data Subnets
- Purpose: Databases, caches, storage services
- Auto-assign public IPs: No
- Typical usage: 20% of VPC space

## AWS Constraints

- Minimum subnet size: /28 (16 IPs, 11 usable)
- AWS reserves 5 IPs per subnet:
  - Network address (x.x.x.0)
  - VPC router (x.x.x.1)
  - DNS server (x.x.x.2)
  - Future use (x.x.x.3)
  - Broadcast (x.x.x.255)

## Examples

### Development VPC (Small)
```hcl
module "dev_vpc" {
  source = "../modules/vpc-core"
  
  vpc_cidr           = "10.0.0.0/20"  # 4,096 IPs
  environment        = "dev"
  region_code        = "use1"
  availability_zones = ["us-east-1a", "us-east-1b"]
}
```

### Production VPC (Large)
```hcl
module "prod_vpc" {
  source = "../modules/vpc-core"
  
  vpc_cidr           = "10.0.0.0/16"  # 65,536 IPs
  environment        = "prod"
  region_code        = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  
  enable_ipv6 = true
  
  tags = {
    Environment = "production"
    CostCenter  = "engineering"
    Compliance  = "SOC2"
  }
}
```

## Migration Notes

If migrating from manual subnet_bits configuration:
1. Remove `subnet_bits` from your configuration
2. Run `terraform plan` to see the changes
3. The module will calculate optimal sizes automatically
4. IP ranges may change, requiring subnet recreation

## License

Copyright (c) Adaptive Technology. All rights reserved.
Licensed under the Apache-2.0 License.
