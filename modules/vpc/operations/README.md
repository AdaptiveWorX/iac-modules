# VPC Operations Module

## Overview

The VPC Operations module provides the operations layer of the AdaptiveWorX 3-layer VPC architecture. This layer hosts CI/CD pipelines, logging infrastructure, monitoring systems, and operational tools that support the entire infrastructure ecosystem.

This module creates:
- VPC optimized for operational workloads
- Subnets for CI/CD and monitoring tools
- Network configuration for log aggregation
- Integration points for operational services
- Layer-specific tagging for connectivity

## Architecture

### 3-Layer VPC Architecture Integration

The Operations layer completes the comprehensive network architecture:
- **Foundation Layer**: Core infrastructure and application workloads
- **Security Layer**: Security tools, monitoring, and compliance
- **Operations Layer**: CI/CD, logging, and operational tools (this module)

Connectivity rules (managed by vpc-connectivity module):
- Foundation → Operations (allowed)
- Security → Operations (allowed)
- Operations → Foundation/Security (restricted by default)

### Subnet Architecture

- **Public Subnets**: Build agents requiring external package access
- **Private Subnets**: Internal CI/CD systems, monitoring tools
- **Data Subnets**: Log storage, metrics databases, artifact repositories

## Usage

```hcl
module "vpc_operations" {
  source = "git::https://github.com/AdaptiveWorX/iac-modules.git//modules/vpc-operations?ref=v1.0.0"

  environment        = "sdlc"
  vpc_cidr          = "10.194.0.0/16"  # Unique from other layers
  region_code       = "use1"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
  subnet_count      = 6  # Match the number of AZs

  # NAT Gateway for package downloads
  enable_nat_gateway = true
  single_nat_gateway = false  # HA for operations

  # VPC Endpoints for AWS services
  interface_endpoints = [
    "ec2", "ecs", "ecr", "ecr.dkr",
    "s3", "logs", "monitoring",
    "codebuild", "codecommit", "codedeploy"
  ]

  # Enhanced monitoring
  enable_flow_logs = true
  flow_logs_destination = "cloud-watch-logs"

  tags = {
    Environment = "sdlc"
    Layer       = "operations"   # Critical for connectivity
    Region      = "us-east-1"    # Used by vpc-connectivity
    ManagedBy   = "Terraform"
    Purpose     = "DevOps"
  }
}
```

## Features

### CI/CD Infrastructure Support
- Isolated network for build and deployment systems
- Support for containerized build agents
- ECR endpoints for container registry access
- CodeBuild/CodeDeploy integration

### Logging and Monitoring
- Centralized log aggregation infrastructure
- CloudWatch Logs integration
- Metrics collection and storage
- Support for ELK/OpenSearch deployments

### Artifact Management
- S3 endpoints for artifact storage
- ECR access for container images
- Package manager proxy support
- Secure artifact distribution

### Operational Tools
- Support for Jenkins, GitLab CI, GitHub Actions runners
- Monitoring tools (Prometheus, Grafana)
- Log analysis platforms
- Infrastructure automation tools

### Layer Connectivity
- Receives connections from Foundation and Security layers
- Restricted outbound access to other layers
- Internet access for package downloads via NAT

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | CIDR block for the VPC | string | - | yes |
| environment | Environment name (sdlc, stage, prod) | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| region_code | AWS region code | string | - | yes |
| subnet_count | Number of subnets per tier | number | 2 | no |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT Gateway | bool | false | no |
| interface_endpoints | List of interface endpoints | list(string) | [] | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | false | no |
| flow_logs_destination | Destination for flow logs | string | "s3" | no |
| tags | Additional tags for resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr | CIDR block of the VPC |
| subnet_ids | Map of subnet IDs by tier |
| nat_gateway_ids | List of NAT Gateway IDs |
| route_table_ids | Map of route table IDs |
| endpoint_ids | Map of VPC endpoint IDs |
| layer | Layer identifier (always "operations") |

## Operational Best Practices

### Build Infrastructure
1. Dedicated subnets for build agents
2. Scalable compute capacity for CI/CD
3. Secure access to source code repositories
4. Artifact caching for performance

### Logging Architecture
- Centralized log collection from all layers
- Log retention policies based on compliance
- Real-time log streaming capabilities
- Integration with SIEM tools

### Monitoring Setup
- Metrics collection from all VPC layers
- Custom dashboards for operational visibility
- Alert routing and escalation
- Performance baseline establishment

### Cost Optimization
- Spot instances for build agents
- Scheduled scaling for non-production hours
- S3 lifecycle policies for artifacts
- Reserved capacity for critical tools

## Multi-Region Deployment

When deploying across multiple regions:
1. Each region gets its own Operations VPC
2. Consistent CIDR allocation (e.g., 10.194.0.0/16 for us-east-1)
3. Cross-region artifact replication via S3
4. Centralized logging to primary region possible
5. Regional build capacity for latency optimization

## Integration with vpc-connectivity

The Operations layer VPC is automatically discovered and connected by the vpc-connectivity module based on tags:
- `Environment`: Identifies the environment
- `Layer`: Must be set to "operations"
- `Region`: Identifies the AWS region

Connectivity is established according to the layer matrix:
- Accepts connections from Foundation and Security layers
- Limited outbound connectivity by design
- No direct peering between Operations VPCs

## CI/CD Pipeline Integration

### GitHub Actions
- Self-hosted runners in private subnets
- OIDC authentication support
- Secure secrets management
- Artifact caching in S3

### Jenkins
- Master nodes in private subnets
- Agent scaling with ECS/EKS
- Plugin repository mirroring
- Build artifact storage

### Container Registries
- ECR endpoints for low-latency pulls
- Cross-account image sharing
- Vulnerability scanning integration
- Image lifecycle policies

## Requirements

- Terraform >= 1.5.0
- AWS Provider >= 5.0
- Proper tagging for connectivity discovery
- IAM permissions for CI/CD services

## Related Modules

- **vpc-foundation**: Foundation layer VPC module
- **vpc-security**: Security layer VPC module
- **vpc-connectivity**: Manages connectivity between VPC layers
