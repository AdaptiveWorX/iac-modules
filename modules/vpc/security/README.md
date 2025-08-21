# VPC Security Module

## Overview

The VPC Security module provides the security layer of the AdaptiveWorX 3-layer VPC architecture. This layer hosts security tools, monitoring systems, compliance resources, and serves as a controlled gateway for security operations.

This module creates:
- VPC with security-focused configuration
- Subnets optimized for security tools
- Security group foundations
- Network ACL configurations
- VPC Flow Logs
- GuardDuty integration points
- Layer-specific tagging for connectivity

## Architecture

### 3-Layer VPC Architecture Integration

The Security layer is part of a comprehensive network architecture:
- **Foundation Layer**: Core infrastructure and application workloads
- **Security Layer**: Security tools, monitoring, and compliance (this module)
- **Operations Layer**: CI/CD, logging, and operational tools

Connectivity rules (managed by vpc-connectivity module):
- Foundation → Security (allowed)
- Security → Operations (allowed)
- Operations → Security (not allowed by default)

### Subnet Architecture

- **Public Subnets**: Security appliances requiring internet access
- **Private Subnets**: Internal security tools and monitoring systems
- **Data Subnets**: Security data storage and analysis

## Usage

```hcl
module "vpc_security" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-security?ref=v1.0.0"

  environment        = "sdlc"
  vpc_cidr          = "10.193.0.0/16"  # Different from foundation
  region_code       = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  subnet_count      = 6  # Match the number of AZs

  # NAT Gateway for security tools
  enable_nat_gateway = true
  single_nat_gateway = false  # HA for security layer

  # VPC Endpoints for secure AWS service access
  interface_endpoints = [
    "ec2", "ssm", "logs", "guardduty",
    "securityhub", "config", "cloudtrail"
  ]

  # Flow Logs
  enable_flow_logs = true
  flow_logs_destination = "s3"  # or "cloud-watch-logs"

  tags = {
    Environment = "sdlc"
    Layer       = "security"     # Critical for connectivity
    Region      = "us-east-1"    # Used by vpc-connectivity
    ManagedBy   = "Terraform"
    Compliance  = "Required"
  }
}
```

## Features

### Security-First Design
- Isolated network for security tools
- Strict network ACL rules
- Enhanced VPC Flow Logs
- GuardDuty-ready configuration

### VPC Flow Logs
- Capture all network traffic metadata
- Support for S3 or CloudWatch Logs destinations
- Automatic log retention policies
- Integration with security analysis tools

### Security Service Endpoints
Pre-configured interface endpoints for AWS security services:
- GuardDuty
- Security Hub
- AWS Config
- CloudTrail
- Systems Manager

### Network Segmentation
- Separate subnets for different security tool categories
- Isolation between security layers
- Controlled access via Security Groups and NACLs

### Layer Connectivity
- Receives connections from Foundation layer
- Can connect to Operations layer for log shipping
- Isolated from external accounts by default

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------
| vpc_cidr | CIDR block for the VPC | string | - | yes |
| environment | Environment name (sdlc, stage, prod) | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| region_code | AWS region code | string | - | yes |
| subnet_count | Number of subnets per tier | number | 2 | no |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT Gateway | bool | false | no |
| interface_endpoints | List of interface endpoints | list(string) | [] | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | true | no |
| flow_logs_destination | Destination for flow logs | string | "s3" | no |
| tags | Additional tags for resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| subnet_ids | Map of subnet IDs by tier |
| security_group_ids | Map of security group IDs |
| flow_logs_id | VPC Flow Logs ID |
| route_table_ids | Map of route table IDs |
| layer | Layer identifier (always "security") |

## Security Best Practices

### Network Security
1. All subnets have dedicated NACLs with explicit rules
2. Default security group denies all traffic
3. VPC Flow Logs enabled by default
4. Private endpoints for AWS service access

### Compliance Features
- Full traffic logging via VPC Flow Logs
- CloudTrail integration ready
- Config rules can be applied to all resources
- Security Hub findings aggregation support

### Monitoring Integration
- CloudWatch metrics for all network components
- VPC Flow Logs analysis capabilities
- GuardDuty threat detection integration
- Custom metric filters for security events

## Multi-Region Deployment

When deploying across multiple regions:
1. Each region gets its own Security VPC
2. Consistent CIDR allocation (e.g., 10.193.0.0/16 for us-east-1)
3. Cross-region security event aggregation via Security Hub
4. Centralized log collection possible via Operations layer

## Integration with vpc-connectivity

The Security layer VPC is automatically discovered and connected by the vpc-connectivity module based on tags:
- `Environment`: Identifies the environment
- `Layer`: Must be set to "security"
- `Region`: Identifies the AWS region

Connectivity is established according to the layer matrix:
- Accepts connections from Foundation layer
- Can initiate connections to Operations layer
- No direct external connectivity by default

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0
- Proper tagging for connectivity discovery
- Sufficient IAM permissions for security services

## Related Modules

- **vpc-foundation**: Foundation layer VPC module
- **vpc-operations**: Operations layer VPC module  
- **vpc-connectivity**: Manages connectivity between VPC layers
