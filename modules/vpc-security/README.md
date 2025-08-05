# VPC Security Module

This module manages Network Access Control Lists (NACLs) for VPC security, providing subnet-level network traffic control. It creates and configures NACLs for public, private, and data subnet tiers with appropriate inbound and outbound rules.

## Features

- Creates separate NACLs for public, private, and data subnet tiers
- Configures the default NACL to deny all traffic (security best practice)
- Supports both IPv4 and IPv6 traffic rules
- Implements standard security patterns for each subnet tier
- Automatic NACL associations with corresponding subnets
- Comprehensive tagging support

## Architecture

The module implements a defense-in-depth approach with NACLs:

- **Default NACL**: Configured to deny all traffic (fail-secure)
- **Public NACL**: Allows internet-facing traffic (HTTP/HTTPS, SSH, RDP)
- **Private NACL**: Restricts traffic to VPC CIDR and ephemeral ports
- **Data NACL**: Most restrictive, only allows VPC-internal traffic

## Usage

```hcl
module "vpc_security" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-security?ref=v1.0.0"

  vpc_id                 = module.vpc_core.vpc_id
  vpc_cidr               = module.vpc_core.vpc_cidr
  vpc_ipv6_cidr          = module.vpc_core.vpc_ipv6_cidr_block
  default_network_acl_id = module.vpc_core.default_network_acl_id
  
  environment = "prod"
  enable_ipv6 = true
  
  # Subnet IDs from vpc-core module
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
  
  tags = {
    Environment = "prod"
    Project     = "infrastructure"
  }
}
```

## NACL Rules Configuration

### Public NACL Rules

#### Inbound Rules
| Rule # | Protocol | Port | Source | Description |
|--------|----------|------|--------|-------------|
| 100 | TCP | 80 | 0.0.0.0/0 | HTTP traffic |
| 110 | TCP | 443 | 0.0.0.0/0 | HTTPS traffic |
| 120 | TCP | 22 | 0.0.0.0/0 | SSH access |
| 130 | TCP | 3389 | 0.0.0.0/0 | RDP access |
| 200 | TCP | 1024-65535 | 0.0.0.0/0 | Ephemeral ports |

#### Outbound Rules
| Rule # | Protocol | Port | Destination | Description |
|--------|----------|------|-------------|-------------|
| 100 | All | All | 0.0.0.0/0 | All outbound traffic |

### Private NACL Rules

#### Inbound Rules
| Rule # | Protocol | Port | Source | Description |
|--------|----------|------|--------|-------------|
| 100 | All | All | VPC CIDR | All VPC traffic |
| 200 | TCP | 1024-65535 | 0.0.0.0/0 | Ephemeral ports for internet responses |

#### Outbound Rules
| Rule # | Protocol | Port | Destination | Description |
|--------|----------|------|-------------|-------------|
| 100 | All | All | 0.0.0.0/0 | All outbound traffic |

### Data NACL Rules

#### Inbound Rules
| Rule # | Protocol | Port | Source | Description |
|--------|----------|------|--------|-------------|
| 100 | All | All | VPC CIDR | All VPC traffic |

#### Outbound Rules
| Rule # | Protocol | Port | Destination | Description |
|--------|----------|------|-------------|-------------|
| 100 | All | All | VPC CIDR | VPC-only traffic |

## IPv6 Support

When `enable_ipv6 = true` and IPv6 CIDR is provided:
- Duplicate rules are created for IPv6 traffic (rule number + 1)
- IPv6 rules follow the same patterns as IPv4 rules
- ::/0 is used for internet-wide IPv6 access

## Security Considerations

### Defense in Depth
- NACLs provide subnet-level security (stateless)
- Should be used in conjunction with Security Groups (stateful)
- Default deny approach for unknown subnets

### Best Practices
1. **Public Subnets**: Only allow necessary internet-facing ports
2. **Private Subnets**: Restrict to VPC traffic and required ephemeral ports
3. **Data Subnets**: Most restrictive, typically only VPC-internal traffic
4. **Rule Numbering**: Leave gaps between rules for future additions

### Security Recommendations
- Review and restrict SSH/RDP access in public NACLs for production
- Consider using AWS Systems Manager Session Manager instead of direct SSH
- Implement additional rules for specific application requirements
- Monitor VPC Flow Logs to validate NACL effectiveness

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | VPC ID where NACLs will be created | string | n/a | yes |
| vpc_cidr | VPC CIDR block | string | n/a | yes |
| vpc_ipv6_cidr | VPC IPv6 CIDR block | string | null | no |
| default_network_acl_id | Default Network ACL ID to manage | string | n/a | yes |
| environment | Environment name (e.g., sdlc, stage, prod) | string | n/a | yes |
| enable_ipv6 | Whether IPv6 is enabled | bool | true | no |
| public_subnet_ids | List of public subnet IDs | list(string) | n/a | yes |
| private_subnet_ids | List of private subnet IDs | list(string) | n/a | yes |
| data_subnet_ids | List of data subnet IDs | list(string) | n/a | yes |
| tags | Additional tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| public_nacl_id | ID of the public NACL |
| private_nacl_id | ID of the private NACL |
| data_nacl_id | ID of the data NACL |
| default_nacl_id | ID of the default NACL (configured to deny all) |
| nacl_ids | Map of all NACL IDs by tier |
| public_nacl_association_ids | List of public NACL association IDs |
| private_nacl_association_ids | List of private NACL association IDs |
| data_nacl_association_ids | List of data NACL association IDs |

## Troubleshooting

### Common Issues

1. **Connectivity Problems**
   - Check NACL rules for both inbound and outbound traffic
   - Remember NACLs are stateless - both directions need explicit rules
   - Verify ephemeral port ranges for return traffic

2. **IPv6 Connectivity**
   - Ensure `enable_ipv6 = true` and `vpc_ipv6_cidr` is provided
   - Check that IPv6 rules are created (rule numbers + 1)

3. **Application-Specific Ports**
   - Add custom rules for non-standard ports
   - Maintain rule number gaps for easy insertion

## Requirements

- OpenTofu >= 1.10.0
- AWS Provider ~> 6.0
- VPC Core module must be deployed first
