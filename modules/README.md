# Infrastructure as Code Modules

This directory contains reusable Terraform/OpenTofu modules for AWS infrastructure management, with a focus on VPC and networking components.

## VPC Modules Overview

### Core VPC Infrastructure

| Module | Purpose | Status | Version |
|--------|---------|--------|---------|
| [vpc-core](./vpc-core/) | Foundation VPC with subnets, gateways, and DHCP | ✅ Complete | v1.0.0 |
| [vpc-routing](./vpc-routing/) | NAT Gateways, route tables, and routing logic | ✅ Complete | v1.0.0 |
| [vpc-security](./vpc-security/) | Network ACLs and security configurations | ✅ Complete | v1.0.0 |
| [vpc-monitoring](./vpc-monitoring/) | VPC Flow Logs and CloudWatch monitoring | ✅ Complete | v1.0.0 |

### VPC Connectivity & Sharing

| Module | Purpose | Status | Version |
|--------|---------|--------|---------|
| [vpc-peering](./vpc-peering/) | Cross-region VPC peering connections | ✅ Complete | v1.0.0 |
| [vpc-sharing](./vpc-sharing/) | RAM resource sharing across accounts | ✅ Complete | v1.0.0 |
| [vpc-endpoints](./vpc-endpoints/) | VPC endpoints for AWS services | ✅ Complete | v1.0.0 |
| [ram-tagging](./ram-tagging/) | Resource tagging for shared VPCs | ✅ Complete | v1.0.0 |

### Advanced Features

| Module | Purpose | Status | Version |
|--------|---------|--------|---------|
| [flow-logs-analysis](./flow-logs-analysis/) | Advanced flow log analysis and reporting | 🚧 Planned | - |

## Module Dependencies

```
vpc-core
├── vpc-routing
├── vpc-security
├── vpc-monitoring
├── vpc-endpoints
└── vpc-sharing
    └── ram-tagging (in recipient accounts)
```

## Quick Start

### Basic VPC Deployment

```hcl
# 1. Core VPC Infrastructure
module "vpc_core" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-core?ref=v1.0.0"
  
  vpc_cidr           = "10.0.0.0/16"
  environment        = "prod"
  region_code        = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# 2. Routing Configuration
module "vpc_routing" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-routing?ref=v1.0.0"
  
  vpc_id             = module.vpc_core.vpc_id
  environment        = "prod"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Gateway IDs from vpc-core
  igw_id  = module.vpc_core.internet_gateway_id
  eigw_id = module.vpc_core.egress_only_internet_gateway_id
  
  # Subnet IDs from vpc-core
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
}

# 3. Security Configuration
module "vpc_security" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-security?ref=v1.0.0"
  
  vpc_id                 = module.vpc_core.vpc_id
  vpc_cidr               = module.vpc_core.vpc_cidr
  default_network_acl_id = module.vpc_core.default_network_acl_id
  
  environment = "prod"
  
  # Subnet IDs from vpc-core
  public_subnet_ids  = module.vpc_core.public_subnet_ids
  private_subnet_ids = module.vpc_core.private_subnet_ids
  data_subnet_ids    = module.vpc_core.data_subnet_ids
}

# 4. Monitoring Setup
module "vpc_monitoring" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-monitoring?ref=v1.0.0"
  
  vpc_id      = module.vpc_core.vpc_id
  environment = "prod"
  
  # NAT Gateway monitoring
  nat_gateway_ids = module.vpc_routing.nat_gateway_ids
  alarm_email     = "ops@company.com"
}
```

### Advanced Features

```hcl
# 5. VPC Endpoints (Optional)
module "vpc_endpoints" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-endpoints?ref=v1.0.0"
  
  vpc_id              = module.vpc_core.vpc_id
  vpc_cidr            = module.vpc_core.vpc_cidr
  region              = "us-east-1"
  environment         = "prod"
  route_table_ids     = concat(
    module.vpc_routing.private_route_table_ids,
    module.vpc_routing.data_route_table_ids
  )
  endpoint_subnet_ids = module.vpc_core.private_subnet_ids
  
  # Common endpoints
  interface_endpoints = [
    "ec2",
    "ssm",
    "ssmmessages",
    "ec2messages",
    "kms",
    "secretsmanager"
  ]
}

# 6. Cross-Region Peering (Optional)
module "vpc_peering" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-peering?ref=v1.0.0"
  
  providers = {
    aws      = aws
    aws.peer = aws.us_west_2
  }
  
  environment    = "prod"
  current_region = "us-east-1"
  vpc_id         = module.vpc_core.vpc_id
  vpc_cidr       = module.vpc_core.vpc_cidr
  
  route_table_ids = concat(
    [module.vpc_routing.public_route_table_id],
    module.vpc_routing.private_route_table_ids,
    module.vpc_routing.data_route_table_ids
  )
  
  peer_configs = [
    {
      region          = "us-west-2"
      vpc_id          = "vpc-west-region"
      vpc_cidr        = "10.1.0.0/16"
      route_table_ids = ["rtb-west1", "rtb-west2"]
    }
  ]
}
```

## Module Features

### vpc-core
- **Automatic Subnet Sizing**: Intelligent CIDR allocation
- **Multi-AZ Support**: Subnets across all specified AZs
- **IPv6 Support**: Optional dual-stack configuration
- **Three-Tier Architecture**: Public, Private, and Data subnets

### vpc-routing
- **Flexible NAT Gateway Deployment**: Single or multi-AZ
- **IPv6 Routing**: Egress-only Internet Gateway support
- **Per-AZ Route Tables**: Better fault isolation
- **Cost Optimization**: Configurable for development vs production

### vpc-security
- **Defense in Depth**: Separate NACLs for each tier
- **Security Best Practices**: Default deny approach
- **IPv6 Support**: Dual-stack security rules
- **Comprehensive Coverage**: All subnet tiers protected

### vpc-monitoring
- **Dual Destination Support**: S3 or CloudWatch Logs
- **NAT Gateway Monitoring**: Bandwidth and error alerts
- **Configurable Retention**: Automatic log cleanup
- **SNS Notifications**: Email alerts for critical events

### vpc-peering
- **Cross-Region Support**: Multi-region connectivity
- **Automatic Acceptance**: Bidirectional peering setup
- **Route Management**: Automatic route table updates
- **DNS Resolution**: Cross-VPC name resolution

### vpc-sharing
- **Multi-Format Support**: List and map-based account sharing
- **Organization Unit Sharing**: Broad sharing within OUs
- **Descriptive Names**: Better documentation and tracking
- **Flexible Configuration**: Mix of account and OU sharing

### vpc-endpoints
- **Gateway Endpoints**: Free S3 and DynamoDB access
- **Interface Endpoints**: Paid service connectivity
- **Security Groups**: Automatic security configuration
- **Private DNS**: Seamless service integration

### ram-tagging
- **Automatic Discovery**: Finds all shared resources
- **Tag Synchronization**: Maintains naming consistency
- **Cross-Account Support**: Works in recipient accounts
- **Comprehensive Coverage**: VPC, subnets, route tables, gateways

## Best Practices

### Deployment Order
1. **vpc-core**: Foundation infrastructure
2. **vpc-routing**: Network connectivity
3. **vpc-security**: Security controls
4. **vpc-monitoring**: Observability
5. **vpc-endpoints**: Service connectivity (optional)
6. **vpc-peering**: Cross-region connectivity (optional)
7. **vpc-sharing**: Cross-account sharing (optional)
8. **ram-tagging**: Resource tagging in recipient accounts

### Environment Considerations

**Development/Test:**
- Use single NAT Gateway for cost savings
- Minimal flow log retention (7 days)
- Basic endpoint configuration
- Reduced monitoring alerts

**Production:**
- Multi-AZ NAT Gateways for high availability
- Extended flow log retention (30+ days)
- Comprehensive endpoint coverage
- Full monitoring and alerting

### Security Guidelines
- Use private subnets for most workloads
- Implement least-privilege access
- Enable flow logs for security monitoring
- Regular security group and NACL reviews
- Monitor NAT Gateway costs and usage

## Cost Optimization

### NAT Gateway Costs
- **Hourly**: ~$0.045 per hour per NAT Gateway
- **Data Processing**: ~$0.045 per GB
- **Optimization**: Use single NAT Gateway for non-critical environments

### Flow Log Costs
- **S3 Storage**: ~$0.023 per GB per month
- **CloudWatch**: ~$0.50 per GB ingested
- **Optimization**: Use S3 for long-term storage, CloudWatch for real-time analysis

### VPC Endpoint Costs
- **Gateway Endpoints**: Free (S3, DynamoDB)
- **Interface Endpoints**: ~$0.01 per hour per endpoint
- **Optimization**: Only enable required endpoints

## Support

For issues, questions, or contributions:
- **Documentation**: Each module has detailed README files
- **Examples**: See module READMEs for usage examples
- **Versioning**: All modules use semantic versioning
- **Compatibility**: Tested with OpenTofu >= 1.10.0 and AWS Provider ~> 6.0

## License

Copyright (c) Adaptive Technology. All rights reserved.
Licensed under the Apache-2.0 License. 